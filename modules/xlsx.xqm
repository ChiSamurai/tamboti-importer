xquery version "3.0";

module namespace xlsx="http://hra.uni-heidelberg.de/ns/hra-csv2vra/xlsx";

import module namespace unzip = "http://joewiz.org/ns/xquery/unzip";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://hra.uni-heidelberg.de/ns/hra-csv2vra/config" at "config.xqm";
import module namespace functx="http://www.functx.com";

import module namespace vra-gen="http://hra.uni-heidelberg.de/ns/hra-csv2vra/vra-gen" at "vra-gen.xqm";
import module namespace pagination="http://hra.uni-heidelberg.de/ns/hra-csv2vra/pagination" at "pagination.xqm";

(:declare default element namespace "http://schemas.openxmlformats.org/package/2006/content-types";:)

declare namespace xlsx-c = "http://schemas.openxmlformats.org/package/2006/content-types";
declare namespace xlsx-ws = "http://schemas.openxmlformats.org/spreadsheetml/2006/main";
declare namespace xlsx-r = "http://schemas.openxmlformats.org/officeDocument/2006/relationships";
declare namespace xlsx-pr = "http://schemas.openxmlformats.org/package/2006/relationships";
declare namespace vra-ns = "http://www.vraweb.org/vracore4.htm";

declare namespace local = "local";
(:declare namespace tei="http://www.tei-c.org/ns/1.0"; :)


(:declare option exist:serialize "method=html5 media-type=text/html";:)

declare function xlsx:filter($path as xs:string, $type as xs:string, $param as item()*) as xs:boolean {
    if(starts-with($path, $param[1])) then 
        true()
    else 
        false()
};


declare function xlsx:process($path as xs:string,$type as xs:string, $data as item()? , $param as item()*) {
 (: return the XML :)
 $data
};

declare
(:    %templates:wrap:)
function xlsx:unzipXLSX($path as xs:string) {
    let $zip := 
    if (starts-with($path, "http")) then 
            httpclient:get(xs:anyURI($path), true(), ())/httpclient:body/text()
        else 
            util:binary-doc($config:data-root || "/" || $path)

    let $filter := util:function(QName("http://hra.uni-heidelberg.de/ns/hra-csv2vra","xlsx:filter"),3)
    let $process := util:function(QName("http://hra.uni-heidelberg.de/ns/hra-csv2vra","xlsx:process"),4)

    let $xml := compression:unzip($zip, $filter, (), $process, ())
    return 
        <div>
            {
            for $node in $xml return
                $node
            }
        </div>
};

declare
(:    %templates:wrap:)
function xlsx:unzipFile($zipfile as xs:string, $filename as xs:string) {
    let $zip := util:binary-doc($config:data-root || "/" || $zipfile)
    let $filter := util:function(QName("http://hra.uni-heidelberg.de/ns/hra-csv2vra","xlsx:filter"),3)
    let $process := util:function(QName("http://hra.uni-heidelberg.de/ns/hra-csv2vra","xlsx:process"),4)

    let $xml := compression:unzip($zip, $filter, $filename, $process, ())
    return 
        $xml
};

declare function xlsx:unzipFileInMem($fileData as xs:base64Binary, $filename as xs:string) {
    let $filter := util:function(QName("http://hra.uni-heidelberg.de/ns/hra-csv2vra","xlsx:filter"),3)
    let $process := util:function(QName("http://hra.uni-heidelberg.de/ns/hra-csv2vra","xlsx:process"),4)
    let $xml := compression:unzip($fileData, $filter, $filename, $process, ())
    return 
        $xml
};

declare function xlsx:load-worksheet-contents($zipfile-data, $worksheets as node()*){
    for $sheet in $worksheets
        return
            <worksheetContent Id="{$sheet/@Id}">
                <sheetData xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
                {
                    (: extract workheet rows :)
                    for $row in xlsx:unzipFileInMem($zipfile-data, "xl/" || data($sheet/@Target))//xlsx-ws:sheetData/xlsx-ws:row[node()] 
                        let $filenameField := $row//xlsx-ws:c[1]
                        let $columnName := functx:substring-before-match(data($filenameField/@r), "[0-9]")
                        return 
                            (: only take rows with first row (A) not empty :)
                            if ($columnName = "A" and not(functx:trim(data($row//xlsx-ws:c[1])) = "")) then
                                $row
                            else
                                ""
                }
                </sheetData>
            </worksheetContent>
};


declare function xlsx:get-worksheets($workbook-rels as item()*) {
(:    $xml-data/xlsx-ws:workbook/xlsx-ws:sheets/xlsx-ws:sheet:)

    for $sheet in $workbook-rels//xlsx-pr:Relationships/xlsx-pr:Relationship[@Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet"]
    return
        $sheet
};

(:declare function xlsx:get-worksheet-data($xml-data as item()*, $sheetId as xs:string) {:)
(:(:    $xml-data[5]//xlsx-ws:worksheet:):)
(:    for $sheet in $xml-data/xlsx-ws:worksheet return:)
(:        $sheet:)
(:};:)

declare 
(:    %default("type", "sst"):)
function xlsx:get-shared-strings($xml-data as item()*) {
    for $si in $xml-data/xlsx-ws:sst/xlsx-ws:si return 
        $si/xlsx-ws:t/text()
};  


declare function xlsx:getHeading($xml-data as xs:string, $sheetId as xs:integer) {
    $xml-data
};


(:declare:)
(:    %templates:wrap:)
(:function xlsx:loadXLSX($node as node(), $model as map(*), $file as xs:string) {:)
(:    let $xml-data := xlsx:unzipXLSX($file):)
(:    let $shared-strings := xlsx:get-shared-strings($xml-data) :)
(:    return :)
(:        map{:)
(:            "sst" := $shared-strings,:)
(:            "xml-data" := $xml-data:)
(:        }:)
(:};:)

declare
    %templates:wrap
function xlsx:sheet-dropdown($node as node(), $model as map(*)) {
    (: Sheets auslesen :)
    let $worksheet-content := session:get-attribute("mapping")("workbook-content")
    return
        for $sheet in $worksheet-content//xlsx-ws:sheets/xlsx-ws:sheet return
            <option value="{data($sheet/@xlsx-r:id)}">
                {
                    data($sheet/@name)
                }
            </option>
    
};

(:declare :)
(:    %templates:wrap:)
(:function xlsx:getXLSXContent($node as node(), $model as map(*)) {:)
(:    let $zipfile := request:get-uploaded-file-name('fileUpload'):)
(:    return:)
(:        xlsx:getXLSXContent($zipfile):)
(:};:)

declare 
(:    %templates:wrap:)
function xlsx:getXLSXContent($zipfile-data as xs:base64Binary) {
(:    let $files := unzip:list($config:data-root || "/" || $zipfile):)
(:    let $content := xlsx:unzipFile($zipfile, data("[Content_Types].xml")):)
(:    let $files := unzip:list($zipfile-data):)
    let $content := xlsx:unzipFileInMem($zipfile-data, data("[Content_Types].xml"))
    
    let $shared-strings := $content/xlsx-c:Types/xlsx-c:Override[@ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"]
    
(:    let $workbook-rels := xlsx:unzipFile($zipfile, data("xl/_rels/workbook.xml.rels")):)
    let $workbook-rels := xlsx:unzipFileInMem($zipfile-data, data("xl/_rels/workbook.xml.rels"))
    let $worksheets := xlsx:get-worksheets($workbook-rels)
(:    let $workbook-content := xlsx:unzipFile($zipfile, substring(data($content//xlsx-c:Override[@ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"]/@PartName), 2)):)
    let $workbook-content := xlsx:unzipFileInMem($zipfile-data, substring(data($content//xlsx-c:Override[@ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"]/@PartName), 2))
    
    let $worksheet-contents := xlsx:load-worksheet-contents($zipfile-data, $worksheets)

    let $workbook := $content/xlsx-c:Types/xlsx-c:Override[@ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"]
    let $shared-strings-content := xlsx:get-shared-strings(xlsx:unzipFileInMem($zipfile-data, substring(data($shared-strings/@PartName), 2)))
    let $mapping := map{
                "content" := $content,
                "workbook" := $workbook,
                "workbook-content" := $workbook-content,
                "workbook-rels" := $workbook-rels,
                "worksheets" := $worksheets, 
                "worksheets-content-infos" := $content/xlsx-c:Types/xlsx-c:Override[@ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"],
                "worksheet-contents" := $worksheet-contents,
(:                "sharedStrings" := $shared-strings,:)
                "sharedStringsFile" := substring(data($shared-strings/@PartName), 2),
                "shared-strings" := $shared-strings-content
                }
    let $useless := session:set-attribute("mapping", $mapping)
    return
        $mapping

};

declare
    %templates:wrap
function xlsx:show-worksheet-content($node as node(), $model as map(*), $worksheet-id as xs:string, $rowId as xs:integer) {
    for $row in $model("worksheet-contents")[@Id=$worksheet-id]/xlsx-ws:sheetData/xlsx-ws:row
        (: WORK VRA generieren:)
        return vra-gen:rowToWorkVRA($row)
};

declare
    %templates:wrap
function xlsx:session-values($node as node(), $model as map(*)) {
    let $mapping := session:get-attribute("mapping")
    return 
(:        session:get-attribute-names():)
        $mapping("content")
};

declare function xlsx:get-values($row as node()) {
    let $shared-strings := session:get-attribute("mapping")("shared-strings")
    return
        <translated xmlns="local">
        {
            for $column in $row/xlsx-ws:c
                let $columnNr := functx:substring-before-match(data($column/@r), "[0-9]")
                return 
                    <column id="{$columnNr}">
                    {
                    if (data($column/@t) = "s") then
                            $shared-strings[xs:integer($column//xlsx-ws:v/text()) + 1]
                        else
                            $column//xlsx-ws:v/text()
                    }
                    </column>
        }
        </translated>
};

declare function xlsx:headings($row as node()) {
    let $headings := xlsx:get-values($row)
    return
        <div>
            <heading>
                {$headings}
            </heading>
        </div>
};

declare function xlsx:countRows() {
    let $sheetId := session:get-attribute("sheetId")
    let $mapping := session:get-attribute("mapping")
    let $worksheet-data := $mapping("worksheet-contents")[@Id=$sheetId]/xlsx-ws:sheetData
    return
        count($worksheet-data/xlsx-ws:row)
};

declare function xlsx:clearToolSessionVariables() {
    session:get-attribute-names()
    
(:    let $useless := session:set-attribute("mapping", $mapping):)
};