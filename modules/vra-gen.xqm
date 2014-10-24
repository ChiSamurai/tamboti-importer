xquery version "3.0";

module namespace vra-gen="http://hra.uni-heidelberg.de/ns/hra-csv2vra/vra-gen";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://hra.uni-heidelberg.de/ns/hra-csv2vra/config" at "config.xqm";
import module namespace xlsx="http://hra.uni-heidelberg.de/ns/hra-csv2vra/xlsx" at "xlsx.xqm";
import module namespace util="http://exist-db.org/xquery/util";
import module namespace functx="http://www.functx.com";
import module namespace tamboti-api="http://hra.uni-heidelberg.de/ns/hra-csv2vra/tamboti-api" at "tamboti-api.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlsx-ws = "http://schemas.openxmlformats.org/spreadsheetml/2006/main";
declare namespace vra-ns = "http://www.vraweb.org/vracore4.htm";
declare namespace local = "local";

declare function vra-gen:getRows() {
    let $sheetId := session:get-attribute("sheetId")
    let $mapping := session:get-attribute("mapping")
    let $shared-strings := session:get-attribute("mapping")("shared-strings")
    let $worksheet-data := $mapping("worksheet-contents")[@Id=$sheetId]/xlsx-ws:sheetData/xlsx-ws:row

    for $row in $worksheet-data
        let $values :=
            if (empty($shared-strings)) then
                ""
                (:  FALLUNTERSCHEIDUNG für nicht-xlsx :)
            else
                xlsx:get-values($row)

        return
            $values
};

declare function vra-gen:getFileList($start as xs:integer) as item()*{
(:    let $sheetId := session:get-attribute("sheetId"):)
(:    for $filename in :)
(:    return:)
(:        $filename:)
        let $test :=
            for $i in data(session:get-attribute("filelist"))
                return $i
        return ($test)
};

declare function vra-gen:rowToWorkVRA($row as node()) {
    let $shared-strings := session:get-attribute("mapping")("shared-strings")

    let $values :=
        if (empty($shared-strings)) then
            ""
            (:  FALLUNTERSCHEIDUNG für nicht-xlsx :)
        else
            xlsx:get-values($row)
    return
        vra-gen:work-vra($values, "", "", <div></div>)
};

declare function vra-gen:collection-vra($collection-uuid) {
    let $vra-collection-xml :=
        <vra xmlns="http://www.vraweb.org/vracore4.htm" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.vraweb.org/vracore4.htm http://cluster-schemas.uni-hd.de/vra-strictCluster.xsd" xmlns:ext="http://exist-db.org/vra/extension">
            <collection id="{$collection-uuid}" source="" refid="{$collection-uuid}"/>
        </vra>
    return 
        $vra-collection-xml
};


declare function vra-gen:work-vra($values as node()*, $collectionUUID as xs:string, $workUUID as xs:string, $imgRows as node()*) {
(:    let $creatorUUID :=     :) 
 
    (: Generate UUIDs if not submitted  :)
    let $collectionUUID :=
        if($collectionUUID = "") then "c_" || util:uuid()
        else $collectionUUID

    let $workUUID :=
        if($workUUID = "") then "w_" || util:uuid()
        else $workUUID
    
    let $source := session:get-attribute("project-name")

    let $subjectIDs := tokenize(data($values//local:column[@id="AH"]), "[;]")
    let $subjects:= tokenize(data($values//local:column[@id="AG"]), "[;]")

    let $worktypeIDs := tokenize(data($values//local:column[@id="N"]), "[;]")
    let $worktype:= tokenize(data($values//local:column[@id="M"]), "[;]")
    
    let $techniqueIDs := tokenize(data($values//local:column[@id="R"]), "[;]")
    let $techniques:= tokenize(data($values//local:column[@id="Q"]), "[;]")

    return
        <vra xmlns="http://www.vraweb.org/vracore4.htm" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:ext="http://exist-db.org/vra/extension" xsi:schemaLocation ="http://www.vraweb.org/vracore4.htm http://cluster-schemas.uni-hd.de/vra-strictCluster.xsd">
        	<work id="{$workUUID}" source="Kurs" refid="{$collectionUUID}">
                <agentSet>
                    <agent>
                    {
                        let $creator-id := functx:trim(data($values//local:column[@id="C"]))
                            (: KJC-UUID? :)
                        return 
                            if(fn:starts-with($creator-id, "uuid-")) then
                                let $name := tamboti-api:get-name-string($creator-id)
                                    return
                                        <name vocab="local" type="personal" refid="{$creator-id}">{$name}</name>
                                else
                                    <name vocab="viaf" type="personal" refid="{$creator-id}">{functx:trim(data($values//local:column[@id="B"]))}</name>
                    }
                        
                        <role vocab="marcrelator" type="code">cre</role>
                    </agent>
                </agentSet>
                <dateSet>
                    <date type="{data($values//local:column[@id="I"])}">
                        <earliestDate>
                            <date>{data($values//local:column[@id="H"])}</date>
                        </earliestDate>
                        <latestDate>
                            <date>{data($values//local:column[@id="H"])}</date>
                        </latestDate>
                    </date>
                    <date type="{data($values//local:column[@id="K"])}">
                        <earliestDate>
                            <date>{data($values//local:column[@id="J"])}</date>
                        </earliestDate>
                        <latestDate>
                            <date>{data($values//local:column[@id="J"])}</date>
                        </latestDate>
                    </date>
                </dateSet>
    			<descriptionSet>
                    <description lang="eng" script="Latn" source="{$source}">
                        <text>{data($values//local:column[@id="AF"])}</text>
                        <author>
                            <name vocab="local" type="personal" refid="uuid-58f114af-4bb9-448f-989f-12bb6931de2b">Jeep, Nila</name>
                            <role vocab="marcrelator" type="code">edt</role>
                        </author>
                    </description>
                </descriptionSet>
                <locationSet>
                    <location source="{$source}" type="site">
                        <name type="corporate" vocab="aat/gnd" refid="{data($values//local:column[@id="U"])}">{data($values//local:column[@id="T"])}</name>
                    </location>
                    <location source="{$source}" type="{data($values//local:column[@id="X"])}">
                        <name type="geographic" vocab="aat/gnd" refid="{data($values//local:column[@id="W"])}">{data($values//local:column[@id="V"])}</name>
                    </location>
                    <location source="{$source}" type="{data($values//local:column[@id="AA"])}">
                        <name type="geographic" vocab="aat/gnd" refid="{data($values//local:column[@id="Z"])}">{data($values//local:column[@id="Y"])}</name>
                    </location>
                    <location source="{$source}" type="{data($values//local:column[@id="AD"])}">
                        <name type="geographic" vocab="aat/gnd" refid="{data($values//local:column[@id="AC"])}">{data($values//local:column[@id="AB"])}</name>
                    </location>
                </locationSet>
                <materialSet>
                	<material vocab="aat/gnd" refid="{data($values//local:column[@id="P"])}" type="medium">{data($values//local:column[@id="O"])}</material>
                </materialSet>
                <measurementsSet>
                	<notes>{data($values//local:column[@id="S"])}</notes>
                </measurementsSet>
                <relationSet>
                {
                    for $img in $imgRows
                        return 
                            if(data($img/not(@workEntry="")) or count($imgRows) = 1) then
                                <relation type="imageIs" refid="{data($img/@uuid)}" relids="{data($img/@uuid)}" source="{$source}" pref="true">{data($img//local:column[@id="AJ"])}</relation>
                            else
                                <relation type="imageIs" refid="{data($img/@uuid)}" relids="{data($img/@uuid)}" source="{$source}">{data($img//local:column[@id="AJ"])}</relation>
                }
                </relationSet>
                <rightsSet>
                	<rights type="copyrighted">
                		<rightsHolder>{data($values//local:column[@id="AE"])}</rightsHolder>
                		<text>Copyrighted. {data($values//local:column[@id="AE"])}</text>
                	</rights>
                </rightsSet>
                <stylePeriodSet>
                	<stylePeriod>{data($values//local:column[@id="L"])}</stylePeriod>
                </stylePeriodSet>
                <subjectSet>
                {
                    for $s-id at $pos in $subjectIDs
                        return 
                        	<subject source="{$source}" vocab="aat/gnd" refid="{functx:trim($s-id)}">
                        		<term type="otherTopic">{functx:trim($subjects[$pos])}</term>
                        	</subject>
                }
                </subjectSet>
                <techniqueSet>
                {
                    for $t-id at $pos in $techniqueIDs
                        return 
                        	<technique vocab="aat/gnd" refid="{$t-id}">{functx:trim($techniques[$pos])}</technique>
                }
                </techniqueSet>
                <textrefSet>
                	<textref>
                		<note>{data($values//local:column[@id="AI"])}</note>
                	</textref>
                </textrefSet>
                <titleSet>
                	<title type="{data($values//local:column[@id="E"])}" pref="true" lang="eng" script="Latn">{data($values//local:column[@id="D"])}</title>
                </titleSet>
                <worktypeSet>
                    {
                        for $w-id at $pos in $worktypeIDs
                            return
                            	<worktype vocab="aat/gnd" source="{$source}" refid="{functx:trim($w-id)}">
                            	    {functx:trim($worktype[$pos])}
                                </worktype>
                    }
                </worktypeSet>                
            </work>
        </vra>
};

declare function vra-gen:rowToImageVRA($row as node(), $collectionUUID as xs:string, $workUUID as xs:string, $imageUUID as xs:string) {
    let $shared-strings := session:get-attribute("mapping")("shared-strings")
    let $source := session:get-attribute("project-name")


    (: Generate UUIDs   :)
    let $collectionUUID :=
        if(empty($collectionUUID)) then "c_" || util:uuid()
        else $collectionUUID

    let $workUUID :=
        if(empty($workUUID)) then util:uuid()
        else $workUUID

    let $imageUUID :=
        if(empty($imageUUID)) then util:uuid()
        else $imageUUID
    
    
    let $values :=
        if (empty($shared-strings)) then
            ""
            (:  FALLUNTERSCHEIDUNG für nicht-xlsx :)
        else
            xlsx:get-values($row)
    return
        <vra xmlns="http://www.vraweb.org/vracore4.htm" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.vraweb.org/vracore4.htm http://cluster-schemas.uni-hd.de/vra-strictCluster.xsd"	xmlns:ext="http://exist-db.org/vra/extension">
            <image id="{$imageUUID}" source="{$source}" refid="{$collectionUUID}" href="{data($row//local:column[@id="A"])}">
                <agentSet>
                    <agent>
                        <name vocab="local" refid="uuid-edeaf4e7-ee99-5733-a841-fdb06decebb5" pref="false" type="corporate">Cluster of Excellence "Asia and Europe in a Global Context", Heidelberg University.</name>
                        <role vocab="marcrelator" type="code">mdc</role>
                    </agent>
                    <agent>
                        <name vocab="local" refid="$uuid$" pref="true" type="corporate">{$source}</name>
                        <role vocab="AAT" refid="300202383">digitizing</role>
                    </agent>
                    <agent>
                        <name vocab="local" refid="{data($row//local:column[@id="AL"])}" pref="true" type="($corporate$)">{data($row//local:column[@id="AM"])}</name>
                        <role vocab="marcrelator" type="code">pht</role>
                    </agent>
                </agentSet>
                <dateSet>
                    <date type="creation">
                        <earliestDate>{data($row//local:column[@id="AK"])}</earliestDate>
                        <latestDate>{data($row//local:column[@id="AK"])}</latestDate>
                    </date>
                    <date type="view">
                        <earliestDate></earliestDate>
                        <latestDate></latestDate>
                    </date>
                </dateSet>
                <descriptionSet>
                    <description lang="eng" script="Latn" source="{$source}">
                        <text>{data($row//local:column[@id="AJ"])}</text>
                    </description>
                </descriptionSet>
                <locationSet>
                    <location type="repository">
                        <name vocab="local" refid="uuid-a86fcf82-1200-58c6-91d6-2d537f5b58e2" type="corporate">Heidelberg Research Architecture, Visual Resources</name>
                        <name type="geographic" vocab="TGN" refid="7005177" extent="inhabited place">Heidelberg</name>
                    </location>
                </locationSet>
                <measurementsSet>
                    <measurements type="resolution" unit="ppi"/>
                    <measurements type="width" unit="px"/>
                    <measurements type="height" unit="px"/>
                    <measurements type="fileSize" unit="kb"/>
                    <measurements type="bitDepth" unit="bit"/>
                </measurementsSet>
                <relationSet>
                    <relation type="imageOf" relids="{$workUUID}" refid="{$workUUID}" source="($project Name$)">{data($row//local:column[@id="AJ"])}</relation>
                </relationSet>
                <rightsSet>
                    <notes>The Priya Paul Collection. Reproduced with kind permission of the collector.</notes>
                    <rights type="copyrighted">
                        <rightsHolder/>
                        <text>{data($row//local:column[@id="AO"])}</text>
                    </rights>
                </rightsSet>
                <sourceSet>
                    <source>
                        <name type="electronic">filename</name>
                        <refid type="other">{data($row//local:column[@id="A"])}</refid>
                    </source>
                </sourceSet>
                <techniqueSet>
                    <technique vocab="local" refid="uuid-fc6b0d7d-c757-5bc2-aa52-b2c59bbd52f1">digital imaging</technique>
                </techniqueSet>
                <textrefSet>
                	<textref>
                		<note>{data($row//local:column[@id="AN"])}</note>
                	</textref>
                </textrefSet>
                <titleSet>
                    <title lang="eng" script="Latn" type="generalView">{data($row//local:column[@id="AJ"])}</title>
                </titleSet>
                <worktypeSet>
                    <worktype vocab="AAT" refid="300215302">digital images</worktype>
                </worktypeSet>
            </image>
        </vra>
    };
  
declare function vra-gen:seperate-rows() {
    let $rows := vra-gen:getRows()
    let $split :=
        <split>
            {
                for $row in $rows
                return
                    (: get single-line entries -> 1x work, 1x image :) 
                    if (functx:trim(data($row/local:column[@id="F"])) = "") then
                        <single>{$row}</single>
                    else
                    (: multi-line entries: get Group-ID :)
                        <multi groupId="{data($row/local:column[@id="F"])}">{$row}</multi>
            }
        </split>
        
    (: Process multi-line entries :)
    let $groupIds := distinct-values(data($split//multi//local:column[@id="F"]))
    return
        <groups>
        {
            for $groupId in $groupIds
                return 
                    <imageGroup id="{$groupId}">
                        {
                            for $groupRows in $split//multi[@groupId=$groupId]
                            return
                                <imageEntry filename="{$groupRows//local:translated/local:column[@id="A"]}" workEntry="{$groupRows//local:translated/local:column[@id="G"]}" uuid="i_{util:uuid()}">
                                    {
                                      $groupRows//local:translated/local:column
                                    }
                                </imageEntry>
                        }
                    </imageGroup>
            ,
            for $singleRow in $split//single
            return 
                <imageGroup>
                    {
                            <imageEntry filename="{$singleRow//local:translated/local:column[@id="A"]}" workEntry="{$singleRow//local:translated/local:column[@id="F"]}" uuid="i_{util:uuid()}">
                            {$singleRow//local:translated/local:column}
                            </imageEntry>
                    }
                </imageGroup>
        }
    </groups>
};
    
declare
function vra-gen:generateVRAFiles($start as xs:integer) {
    let $collectionUUID := "c_" || util:uuid()
    let $sepRows := vra-gen:seperate-rows()
    return
        <vraFiles>
            {
(:                for $group in $sepRows[@id="1"]:)
            for $group in $sepRows//imageGroup[position() > ($start - 1)]
                return
                    (:  get Entry for generating work :)
                    let $workRow := $group//imageEntry[not(@workEntry="")]
                    let $work-uuid := "w_" || util:uuid()
                    return
                        <group>
                            <imageVRA>
                            {
                            for $imgRow in $group//imageEntry
                                return 
                                    vra-gen:rowToImageVRA($imgRow, $collectionUUID, $work-uuid,  data($imgRow/@uuid))
                            }
                            </imageVRA>
                            <workVRA>
                            {
                                (: falls "pref" gesetzt, diese workUUID nehmen ansonsten:)
                                if ($workRow) then
                                    vra-gen:work-vra($workRow[1], $collectionUUID, $work-uuid, $group//imageEntry)
                                else
                                    vra-gen:work-vra($group//imageEntry[1], $collectionUUID, $work-uuid, $group//imageEntry)
                            }
                            </workVRA>
                        </group>
            }
        </vraFiles>
};

declare
    %templates:wrap
    %templates:default("start", 2)
    %templates:default("colName", "newCollection0815")
function vra-gen:images-request($node as node(), $model as map(*), $start as xs:integer, $colName as xs:string, $project-name as xs:string) {
    (:    set session variables for upload:)
    let $useless := vra-gen:_prepare-session($start, $colName, $project-name)
    return
        <table class="table table-striped table-condensed">
            <tbody>
            {
                for $filename in data(vra-gen:getRows()[position() > ($start - 1)]//local:column[@id="A"])
                return 
                    <tr>
                        <td>
                            <div class="text-center progress progress-bar-danger" filename="{$filename}">{$filename}</div>
                        </td>
                    </tr>
            }
            </tbody>
        </table>
};

declare 
    %templates:no-wrap
    %templates:default("start", 2)
    %templates:default("colName", "newCollection")
function vra-gen:parameters-mask($node as node(), $model as map(*), $start as xs:integer, $colName as xs:string){
    <div class="col-md-12">
        <div class="col-md-2">
            <label for="project-name">Project Name</label>
        </div>
        <div class="col-md-10">
            <input type="text" name="project-name" id="project-name" value="KJC Project" />
        </div>
        <div class="col-md-2">
            <label for="startRow">First row with data: </label>
        </div>
        <div class="col-md-10">
            <input type="text" name="start" id="start" value="{$start}" />
        </div>
        <div class="col-md-2">
            <label for="colName">Name for new collection: </label>
        </div>
        <div class="col-md-10">
            <input type="text" name="colName" id="colName" value="newCollection"/>
        </div>
    </div>
};

declare
    %templates:wrap
    %templates:default("colName", "newCollection")
function vra-gen:upload-button($node as node(), $model as map(*), $colName as xs:string) {
      <button class="doUpload btn btn-primary start disabled">Start import to "{tamboti-api:getLoginUser()}/home/{session:get-attribute("colName")}"</button>
};

declare %private function vra-gen:_prepare-session($start, $colName, $project-name){
    try{
        let $useless1 := session:set-attribute("start", $start)
        let $useless2 := session:set-attribute("colName", $colName)
        let $useless := session:set-attribute("project-name" , $project-name)
        let $useless3 := session:set-attribute("vra", vra-gen:generateVRAFiles($start))
        let $useless4 := session:set-attribute("filename-map", vra-gen:_images-uuid-map())
        return true()
    } catch * {
        false()
    }
};


declare %private function vra-gen:_images-uuid-map() {
    for $imageVRA in session:get-attribute("vra")//imageVRA//vra-ns:image
        return 
            let $filename := data($imageVRA/@href)
            let $uuid := data($imageVRA/@id)
            return
                <image>
                    <filename>{$filename}</filename>
                    <uuid>{$uuid}</uuid>
                </image>

};

declare
    %templates:wrap
function vra-gen:storeWorkVRAs($node as node(), $model as map(*)) {
    let $workUUIDs := tamboti-api:uploadWorkVRAs()
    return
        <ul>
            {
                for $workUUID in $workUUIDs
                return
                    <li>
                        <a href="{$config:tamboti-path}modules/search/index.html?search-field=ID&amp;value={$workUUID}" target="_blank">
                            {$config:tamboti-path}modules/search/index.html?search-field=ID&amp;value={$workUUID}
                        </a>
                    </li>
            }
        </ul>
};

declare
    %templates:wrap
function vra-gen:showTimestamp($node as node(), $model as map(*)) {
    current-dateTime()
};
