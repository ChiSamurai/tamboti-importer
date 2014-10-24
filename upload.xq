xquery version "3.0";

import module namespace xlsx="http://hra.uni-heidelberg.de/ns/hra-csv2vra/xlsx" at "modules/xlsx.xqm";
import module namespace response="http://exist-db.org/xquery/response";

let $zipfile-name := request:get-uploaded-file-name('file')
let $zipfile-data := request:get-uploaded-file-data('file')

(:let $uploadPath := '/db/data/hra-csv2vra':)
(:let $login := xmldb:login($uploadPath, 'admin', 'werdasliestistdoof'):)
(:let $store := xmldb:store($uploadPath, "testfile.xlsx", $zipfile):)
let $useless := xlsx:getXLSXContent($zipfile-data)

    return
        response:redirect-to(xs:anyURI("step1.html"))
(:        $zipfileName:)