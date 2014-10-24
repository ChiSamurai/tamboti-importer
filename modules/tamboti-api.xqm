xquery version "3.0";

module namespace tamboti-api="http://hra.uni-heidelberg.de/ns/hra-csv2vra/tamboti-api";

import module namespace security="http://exist-db.org/mods/security" at "../../tamboti/modules/search/security.xqm";
import module namespace config="http://exist-db.org/mods/config" at "../../tamboti/modules/config.xqm";
import module namespace tamboti-service="http://hra.uni-heidelberg.de/ns/tamboti/tamboti-service" at "../../tamboti/modules/display/tamboti-service.xqm";

import module namespace img="http://hra.uni-heidelberg.de/ns/hra-csv2vra/img" at "img.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace vra-ns="http://www.vraweb.org/vracore4.htm";

declare variable $tamboti-api:ERROR := xs:QName("tamboti-api:error");

(:
 : Bug http://kjc-sv013.kjc.uni-heidelberg.de/redmine/issues/211
 : SECURITY FIX NEEDED!
 :)

declare variable $tamboti-api:username := "editor";
declare variable $tamboti-api:password := "editor";



declare function tamboti-api:getLoginUser() {
    let $user := security:get-user-credential-from-session()[1]
(:    let $user := "editor":)
    return
            <user>
                {
                    $user
                }
            </user>
};

declare function tamboti-api:getHomeCollection($user) {
    <homeCol>
        {
            security:get-home-collection-uri($user)
        }
    </homeCol>
};

declare function tamboti-api:collectionExists($name as xs:string) as xs:boolean{
    let $loginUser := tamboti-api:getLoginUser()
    let $homeCollection := tamboti-api:getHomeCollection($loginUser)
    let $path := $homeCollection || "/" || $name
    return 
        if(xmldb:collection-available($path)) then
            true()
        else
            false()
};

declare function tamboti-api:collectionWriteable($name as xs:string) {
    let $loginUser := tamboti-api:getLoginUser()
    let $homeCollection := tamboti-api:getHomeCollection($loginUser)
    let $path := $homeCollection || "/" || $name
    return 
        try{
            let $colWritable := security:can-write-collection($path)
            return true()
        } catch * {
            false()
        }
};

declare %private function tamboti-api:_createCollection($collection) {
    let $loginUser := tamboti-api:getLoginUser()
    let $homeCollection := tamboti-api:getHomeCollection($loginUser)
    let $path := $homeCollection || "/" || $collection
    return 
        if(not(tamboti-api:collectionExists($path))) then
            (: try to create collection with VRA_images subcol:)
            try {
                system:as-user($tamboti-api:username, $tamboti-api:password, 
                    (
                    tamboti-api:_makeNewPrivateCollection($collection),
                    tamboti-api:_makeNewPrivateCollection($collection || "/" || "VRA_images")
                    )
                )
            } catch tamboti-api:error{
                <error>Caught error {$err:code}: {$err:description}. Message: {$err:value}.</error>
            } catch * {
                false()
            }
        else
            (: collection exists, writeable? :)
            tamboti-api:collectionWriteable($collection)
};

declare function tamboti-api:uploadImage($collection as xs:string, $image-filename as xs:string, $image-VRA, $image-data) {
    let $loginUser := tamboti-api:getLoginUser()
    let $homeCollection := tamboti-api:getHomeCollection($loginUser)
    let $fullPath := $homeCollection || "/" || $collection || "/VRA_images"
    return
        try {
            system:as-user($tamboti-api:username, $tamboti-api:password,
    
                (: create collection or if already exists check if writeable :)
                let $colValid := tamboti-api:_createCollection($collection)
                let $useless := session:set-attribute("collection", $collection)
                let $imageUUID := data($image-VRA//vra-ns:image/@id)
                let $imageExtension := tokenize($image-filename, '\.')[last()]
    
                
                let $new-image-filename := $imageUUID || "." || $imageExtension
                let $storeImage := xmldb:store($fullPath, $new-image-filename, $image-data)

                let $storeVRA := xmldb:store($fullPath, $imageUUID || ".xml", $image-VRA)
    
                (: Update vra:)
                (: -- href :)
                let $document := doc($fullPath || "/" || $imageUUID || ".xml")
                let $update := update replace $document//vra-ns:image/@href with $new-image-filename

                (: -- image-metadata (size, resolution, etc):)
        (: -- image-metadata (size, resolution, etc):)
                let $imgMeta := img:getImageData($fullPath, $new-image-filename)
        
                let $useless := (
                    update value $document//vra-ns:image//vra-ns:measurementsSet/vra-ns:measurements[@type="width"] with data($imgMeta//width),
                    update value $document//vra-ns:image//vra-ns:measurementsSet/vra-ns:measurements[@type="height"] with data($imgMeta//height),
                    update value $document//vra-ns:image//vra-ns:measurementsSet/vra-ns:measurements[@type="fileSize"] with data($imgMeta//filesize),
                    update value $document//vra-ns:image//vra-ns:measurementsSet/vra-ns:measurements[@type="resolution"] with data($imgMeta//resolutionInfo),
                    update value $document//vra-ns:image//vra-ns:measurementsSet/vra-ns:measurements[@type="bitDepth"] with data($imgMeta//bitDepth)
                )

                return true()
            )
        } catch java:org.xmldb.api.base.XMLDBException {
            "error Uploading Image: Path=" || $fullPath
        } catch *{
            "other error"
        }
};

declare %private function tamboti-api:_makeNewPrivateCollection($name as xs:string) {
    let $group-id := "biblio.users"
    let $loginUser := tamboti-api:getLoginUser()
    let $homeCollection := tamboti-api:getHomeCollection($loginUser)
    return 
        (: do not create subfolders for guest:)
        if(empty($loginUser) or $loginUser="guest") then
            false()
        else
            try {
                let $newCol := xmldb:create-collection($homeCollection, $name)
                let $setPermissions := xmldb:set-collection-permissions($newCol, $loginUser, $group-id, util:base-to-integer(0755, 8))
                return
                    true()
            } catch java:org.xmldb.api.base.XMLDBException {
                let $errorMsg :=
                    "Creating collection" || $homeCollection || "/" || $name || " failed"
                return 
                    error($tamboti-api:ERROR, "Creating Collection failed", $errorMsg)
            }

};


declare function tamboti-api:uploadWorkVRAs(){
    let $collection := session:get-attribute("collection")
(:    return $collection:)
    let $workVRAs := session:get-attribute("vra")//workVRA/vra-ns:vra
        
    for $work-VRA in $workVRAs
            let $workUUID := tamboti-api:_storeWorkVRA($work-VRA)
                return $workUUID
};

declare %private function tamboti-api:_storeWorkVRA($work-VRA){
    let $collection := session:get-attribute("collection")
    let $loginUser := tamboti-api:getLoginUser()
    let $homeCollection := tamboti-api:getHomeCollection($loginUser)
    let $fullPath := $homeCollection || "/" || $collection
(:    let $fullPath :=  $collection:)
    let $work-uuid := data($work-VRA//vra-ns:work/@id)

    return
        try {
            system:as-user($tamboti-api:username, $tamboti-api:password,
                let $storeVRA := xmldb:store($fullPath, $work-uuid || ".xml", $work-VRA)
                    return $work-uuid
            )
    } catch java:org.xmldb.api.base.XMLDBException {
            "error storing workVRA: " || $fullPath || "/" ||  $work-uuid || ".xml"
        } catch *{
            "other error"
        }

};

(: If user has no tamboti-credentials force login:)
declare function tamboti-api:login-mask() {
    ""
};

(:Wrapper for fetching TEI from local repository via tamboti:)

declare function tamboti-api:get-person-by-uuid($uuid) {
    tamboti-service:get-person-by-uuid($uuid)
};

declare function tamboti-api:get-name-string($uuid) {
    let $persTEI := tamboti-api:get-person-by-uuid($uuid)//tei:persName[@type="preferred"]
    let $name :=
        if(empty($persTEI/tei:surname)) then
            data($persTEI)
        else
            data($persTEI/tei:surname) || ", " || data($persTEI/tei:forename)
            
    return $name
};

declare function tamboti-api:get-org-by-uuid($uuid) {
    tamboti-service:get-org-by-uuid($uuid)
};