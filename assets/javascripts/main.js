function initAnim(){
    var imgWidth = 20;
    var numImgs = 36;
    var count = 0;
    var elem = $('.loading_icon');
    var animation_load = setInterval(function(){
        var position =  -1 * (count*imgWidth);
        elem.css('background-position','-2px '+position+'px');
        count++;
        if(count == numImgs){
            count = 0
        }
    },20);
}
$(document).ready(function(){


    setTimeout(function(){
        $('.window_scroll_container').mCustomScrollbar({
            mouseWheel: {scrollAmount: 150}
        });
        $('.window_wrap').append($('#ui-datepicker-div'));
        $('#ui-datepicker-div').hide();
    },200);

    //$('select').uniform()
    $('#back_to_projects').on('click', function(e){
        e.preventDefault();
        document.location.href = $(this).attr('href');
    });
    setTimeout(function(){
        $('.textarea-scrollbar').scrollbar();
        $('select').styler({
            selectPlaceholder: 'Choose...',
            selectSmartPositioning: false
        });
        $('input[type=checkbox]').styler();
        $('.jq-selectbox__dropdown > ul').mCustomScrollbar({
            mouseWheel: {scrollAmount: 100}
        });
    },150);

    $('.search_watchers_label').on('click',function(){
        $('.watchers_search_wrapper').slideToggle(300)
        $(this).toggleClass('expand');
    });

    $('#issue-form').on('submit', function(e){
       e.preventDefault();
       var o = {};
       var a = $(this).serializeArray();
       $.each(a, function() {
           if (o[this.name] !== undefined) {
               if (!o[this.name].push) {
                   o[this.name] = [o[this.name]];
               }
               o[this.name].push(this.value || '');
           } else {
               o[this.name] = this.value || '';
           }
       });
       $.post('/ff_create_issue', o, function(rsp){
           if(rsp.status == 'ok'){
               document.location.href = '/ff_result?issue_id='+rsp.issue_id;
               $('#error_message').html('');
               $('.error_message_wrap').addClass('bordered');
               $('#flash_notice').html(rsp.message);
           }
           else if(rsp.status == 'error'){
               $('#error_message').html(rsp.error_message);
               $('.error_message_wrap').addClass('bordered');
           }
           $('.window_scroll_container').mCustomScrollbar("scrollTo","top");
           //$('html, body').animate({
           //    scrollTop: 1
           //}, 1000);
       }, 'json');
   });
});