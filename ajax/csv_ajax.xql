xquery version "3.0" encoding "UTF-8";

import module namespace xlsx="http://hra.uni-heidelberg.de/ns/hra-csv2vra/xlsx" at "../modules/xlsx.xqm";
import module namespace vra-gen="http://hra.uni-heidelberg.de/ns/hra-csv2vra/vra-gen" at "../modules/vra-gen.xqm";
import module namespace pagination="http://hra.uni-heidelberg.de/ns/hra-csv2vra/pagination" at "../modules/pagination.xqm";

declare namespace xlsx-ws = "http://schemas.openxmlformats.org/spreadsheetml/2006/main";
declare namespace local = "local";


declare option exist:serialize "method=html5 media-type=text/html";

let $request-action := request:get-parameter("action", "getXLSXSheetHeader")
let $filename := request:get-parameter("file", "")
    return 
        switch ($request-action)
            case "countRows"
                return
                    let $sheetId := session:get-attribute("sheetId")
                    let $mapping := session:get-attribute("mapping")
                    let $worksheets := $mapping("worksheet-contents")
                    return
                        xlsx:countRows()
                        
            case "showActiveWorksheet"
                return
                    let $sheet-id := session:get-attribute("sheetId")
                    let $mapping := session:get-attribute("mapping")
                    let $worksheets := $mapping("worksheet-contents")
                    return
                        $worksheets[@Id=$sheet-id]/xlsx-ws:sheetData

            case "getActiveWorksheet"
                return
                    session:get-attribute("sheetId")
                    
            case "setActiveWorksheet"
                return
                    let $mapping := session:get-attribute("mapping")
                    let $sheet-id := request:get-parameter("sheetId", 1)
                    let $start := request:get-parameter("start", 2)

                    let $useless := session:set-attribute("sheetId", $sheet-id)
                    let $filelist :=
                        for $i in vra-gen:getRows()[position() > ($start - 1)]//local:column[@id="A"]
                            return 
                                <filename>{data($i)}</filename>
                    let $useless2 := session:set-attribute("filelist", $filelist)
                    return 
                        count($mapping("worksheet-contents")[@Id=$sheet-id]/xlsx-ws:sheetData/xlsx-ws:row)
(:            case "getXLSXSheetHeader":)
(:                return:)
(:                    let $worksheet-id := session:get-attribute("sheetId"):)
(:                    let $xml-data := xlsx:unzipXLSX($filename):)
(:                    let $sheet-header := xlsx:getHeading($xml-data, $worksheet-id):)
(:                        return $xml-data:)
            case "getPagination"
                return
                    let $worksheet-id := session:get-attribute("sheetId")
                    let $active := request:get-parameter("active", 1)
                    let $maxpages := request:get-parameter("maxpages", 5)
                    let $node-prefix := request:get-parameter("nodePrefix", "expaginate")
                    let $ajax-function := request:get-parameter("ajaxFunction", "updateVRAExample")
                    let $mapping := session:get-attribute("mapping")
                    let $count := count($mapping("worksheet-contents")[@Id=$worksheet-id]/xlsx-ws:sheetData/xlsx-ws:row)
                    
                    return
                        pagination:show($count, $active, $maxpages, $node-prefix, $ajax-function)

            case "getRow"

                return
                    let $worksheet-id := session:get-attribute("sheetId")
                    let $row-id := request:get-parameter("rowId", 1)
                    let $mapping := session:get-attribute("mapping")
(:                    let $sheet := xlsx:get-worksheet-data($mapping("worksheet-contents"), $worksheet-id):)
                    let $serialize := xs:integer(request:get-parameter("serialize", 0))
                    let $worksheets := $mapping("worksheet-contents")
(:                    let $row := $sheet/xlsx-ws:sheetData/xlsx-ws:row[$rowNr]:)
                        return
                            <div>
                                <div class="code" data-language="xml" style="width:100%">
                                    <p>
                                        {
                                        let $row := $worksheets[@Id=$worksheet-id]/xlsx-ws:sheetData/xlsx-ws:row[@r=$row-id]
                                        return 
                                            if ($serialize = 0) then
                                                vra-gen:rowToWorkVRA($row)
                                            else 
                                                serialize(vra-gen:rowToWorkVRA($row))
                                        }
                                    </p>
                                </div>
                            </div>
            default
                return
                    ""