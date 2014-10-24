// $(function() {
//     $("#sheetId").change(function (ev) {
//         ev.preventDefault();
//         var $sheetId = $( this ).val();
// /*        var $filename = escape($("#inputFile").val());
//         // console.debug($("#inputFile").val());

//         $.ajax({
//             url: "./ajax/csv_ajax.xql",
//             data: "action=getXLSXSheetHeader&file=" +  $filename + "&sheetId=" + $sheetId,
//             type: 'POST',
//             success: function(data, message) { 
//                 $('#result').html(data); 
//                 console.log("ajax response:" + data);
//                 },
//             error: function (response, message) {
//                 console.debug("ajax request failed:" + response.responseText);
//                 }
//         });
// */
//         $('.example-vra').each(function(i, obj){
//             var $divId = obj.getAttribute("id");
//             // var $selId = $(this).val();
//             if($divId == $sheetId){
//                 // $(obj).show();
//                 $(obj).fadeIn({"queue" : true});
//             }else{
//                 $(obj).hide();
//                 // $(obj).hide();
//             }


//         });
//         //  alert($ (this).val());
        
//         $('#result').attr('data-template-worksheet-id', $(this).val());
//     });
// });

function updatePaginator($className, $nodePrefix, $active){
    $nodePrefix || ($nodePrefix = "pagItem");
    $active || ($active = 1);
    $.get( "ajax/csv_ajax.xql", {'action': 'getPagination', 'ajaxFunction': 'updateVRAExample', 'nodePrefix': 'pagItem', 'active': $active})
        .done(function( data ) {
            $("." + $className).html( data );
        });
}

// NEEDED???
/*function updatePagination($rowNr, $rowCount, $nodeprefix){
    console.debug("rowNr:" + $rowNr + " rowCount:" + $rowCount, "nodeprefix:" + $nodeprefix)
    $("." + $nodeprefix).removeClass("active disabled");
    if($rowNr == 1) $("#" + $nodeprefix + "first").addClass("disabled");
    else if ($rowNr == $rowCount) $("#" + $nodeprefix + "last").addClass("disabled"); 
    $("#" + $nodeprefix + $rowNr).addClass("active");
}
*/

function updateVRAExample($rowNr, $nodeprefix){
    updatePaginator("pagination-container", "test", $rowNr);

    $.get( "ajax/csv_ajax.xql", {'action': 'getRow', 'rowId': $rowNr, 'serialize': 1})
        .done(function( data ) {
            // alert("ready");
            $('#example-container').html( data );
            $(".code").highlight();
    });
    
    // console.debug($('.' + $nodeprefix + '.active a:first-child').html());
    // console.debug(jQuery.get('ajax/csv_ajax.xql?action=getRow&sheetId=rId2&rowId=3&serialize=1'));
}

function setActiveWorksheet($worksheetId){
    $.get( "ajax/csv_ajax.xql", {'action': 'setActiveWorksheet', 'sheetId': $worksheetId})
        .done(function( data ) {
            updateVRAExample(1, data, "test");
    });
    
}

function fileuploader(divId, url, startButtonClass, nextURL){
    var uploaderObj = $("#" + divId).uploadFile({
        url: url, 
        multiple:true,
        fileName:"files",
        returnType:"json",
        showAbort: false,
        showDone:false,
        showDelete:false,
        autoSubmit: false,
        showProgress: true,
        showFileCounter: false,
        // maxFileCount: 1,
        // showStatusAfterSuccess: false,
        // allowedTypes: "jpg,png,gif,tif", 
        formData: { action: 'uploadFile'}, 
        onSelect:function(files){
            // console.dir(files);
            var i;
            // console.dir(files);
            for(i = 0; i < files.length; i++){

                var divSearch = $(".progress[filename|='" + files[i].name + "']");
                // newly selected file only valid if in filelist and not yet selected
                if (divSearch.length == 1 && !divSearch.hasClass("progress-bar-success")){
                    divSearch.removeClass("progress-bar-danger").addClass("progress-bar-success");
                    //if all files were selected, activate import Buttons
                    if($('.progress-bar-danger').size() == 0)
                        $('.' + startButtonClass).removeClass("disabled");
                }
                else{
//                    files;
                }
            }
            return true; //to allow file submission.
        },
        onSubmit:function(files) {
//            console.dir(files);
        },
        afterUploadAll:function()
        {
            // alert("done");
            // Binary Images are stored, now trigger saving the Work XMLs
            if(nextURL)
                $(location).attr('href',nextURL);
        }
        
        // onError: function(files,status,errMsg){
        //     var i;
        //     for(i = 0; i < files.length; i++){
        //         $(".progress[filename|='" + files[i] + "']").removeClass("progress-bar-info").addClass("progress-bar-danger");
        //     }
        //}
    });
    return uploaderObj;
}


$(document).ready(function(){
});
