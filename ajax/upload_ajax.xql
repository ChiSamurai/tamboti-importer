xquery version "3.0";

import module namespace json="http://www.json.org";
import module namespace vra-gen="http://hra.uni-heidelberg.de/ns/hra-csv2vra/vra-gen" at "../modules/vra-gen.xqm";
import module namespace tamboti-api="http://hra.uni-heidelberg.de/ns/hra-csv2vra/tamboti-api" at "../modules/tamboti-api.xqm";

declare namespace vra-ns="http://www.vraweb.org/vracore4.htm";
declare namespace expath="http://expath.org/ns/pkg";
declare namespace upload="http://exist-db.org/eXide/upload";

declare option exist:serialize "media-type=application/xml";

let $action := request:get-parameter("action", "")
let $start := request:get-parameter("start", 2)
let $filelist := vra-gen:getFileList($start)

return
    switch ($action)
        case "uploadFile"
            return
                let $collection := session:get-attribute("colName")
                let $vra := session:get-attribute("vra")

                let $image-name := request:get-uploaded-file-name('files')
                let $image-data := request:get-uploaded-file-data('files')

                let $result := 
                    (: check if name exists and filename is in list:)
                    if (exists($image-name) and $filelist = $image-name) then
                        try {
                            (: get image VRA and save it:)
                            let $imageVRA := $vra//imageVRA/vra-ns:vra[vra-ns:image/@href=$image-name]
                            return
                                tamboti-api:uploadImage($collection, $image-name, $imageVRA, $image-data)
                        } catch * {
                            concat (
                                '[',
                                json:xml-to-json(
                                    <result>
                                        <name>{$image-name}</name>
                                        <error>{$err:code, $err:value, $err:description}</error>
                                    </result>
                                ),
                                ']'
                            )
                        }
                    else
                        <data>
                            <collection>{$collection}</collection>
                            <image-name>{$image-name}</image-name>
                            <image-name>{$filelist}</image-name>
                        </data>
                return 
                    $result
        case "getVRA"
            return
                let $vra := vra-gen:generateVRAFiles($start)
                let $name := 'Bani_Abidi_2009_p05.jpg'
                let $imageVRA := $vra//imageVRA/vra-ns:vra[vra-ns:image/@href=$name]
                let $imageUUID := data($imageVRA//vra-ns:image/@id)
                return 
                    $imageUUID
        default
            return
                let $binaryCollection := '/db/data/hra-csv2vra/binaries'
                (: vra-gen:seperate-rows():)
                let $vra := vra-gen:generateVRAFiles($start)
                for $imagesVRA in $vra//imageVRA/vra-ns:vra
                return
                    $imagesVRA

    
