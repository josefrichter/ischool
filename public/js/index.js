$(document).ready(function() {
  
	$.getJSON("http://api.flickr.com/services/feeds/photos_public.gne?id=53456090@N02&tags=homepage&format=json&jsoncallback=?",
	  function(data){
			console.log(data);
	    $.each(data.items, function(i,item){
	      //$("<img/>").attr("src", item.media.m).appendTo("#flickr_pics");
				$(".pics_wrapper").append("<div class=\"polaroid\"><img src=\""+item.media.m+"\" alt=\"Picture\" /><p>&nbsp;"+item.title+"&nbsp;</p></div>");
	      //if ( i == 5 ) return false;
	    });
			polaroidize();
	  });
	
}); // end jQuery
