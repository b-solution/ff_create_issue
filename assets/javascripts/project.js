$(document).ready(function(){

    $('.clear_search').on('click',function(){
       $('#search').val('')
    });

    function start_search(periodicity){
        var search_string = $('#search').val().trim(),
            default_list = $('#projects').html();
        setInterval(function(){
            var new_search_string = $('#search').val().trim(),
                flag = false;
            if(new_search_string !== search_string){
                search_string = new_search_string;
                $('#projects li').each(function(){
                    $(this).removeClass('nopadding');
                    $(this).removeClass('fade');
                    if($(this).html().toLowerCase().indexOf(search_string.toLowerCase()) === -1){
                        $(this).addClass('fade');
                        $(this).removeClass('nopadding');
                        flag = true;
                    } else {
                        $(this).addClass('nopadding')
                    }
                });
                if(!flag){
                    $('#projects').html(default_list);
                }
                else{
                    var lis = $('#projects li.fade').detach();
                    $('#projects').append(lis);
                }
            }
        }, periodicity);
    };


    start_search(500);
});