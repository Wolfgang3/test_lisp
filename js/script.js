/*
$(document).ready(function(){
  if ( $('input[name="select-repos"]').length  > 0) {
    $('input[name="select-repos"]').change(function() {
    console.log("click");
    var vals = $('input[name="select-repos"]:checked').map(function() {
        return $(this).val();
    }).get().join(" ");

    $('#repo-checked').val(vals);
    });

    $('input[name="select-asana-project"]').change(function() {
    console.log("click");
    var vals = $('input[name="select-asana-project"]:checked').map(function() {
        return $(this).val();
    }).get().join(" ");

    $('#asana-project-checked').val(vals);
    });
  }
});
*/

 $(document).ready(function(){
    $("#start-date").datepicker({
        numberOfMonths: 1,
        dateFormat: 'yy/mm/dd',
        onSelect: function(selected) {
          $("#end-date").datepicker("option","minDate", selected)
        }
    });
    $("#end-date").datepicker({ 
        numberOfMonths: 1,
        dateFormat: 'yy/mm/dd',
        onSelect: function(selected) {
           $("#start-date").datepicker("option","maxDate", selected)
        }
    });  
});