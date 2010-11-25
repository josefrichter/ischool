$(document).ready(function() {
  
	//var sets_list_url = "http://api.flickr.com/services/rest/?method=flickr.photosets.getList&api_key=c225faf9fcaad1dec0c52b74b8129992&user_id=86832359@N00&format=json&jsoncallback=?"
	var sets_list_url = "http://api.flickr.com/services/rest/?method=flickr.photosets.getList&api_key=5d01332aa12fc3a028d37f20cc2d0659&user_id=53456090@N02&format=json&jsoncallback=?"
  $.getJSON(sets_list_url, function(data){
		//console.log(data);
		$.each(data.photosets.photoset, function(i,set){
			// append wrapper for the photoset
			//$("#body").append("<div class=\"pics_wrapper\" id=\"wrapper_"+i+"\"><span class=\"gallery_name\"><h3>"+set.title._content+"</h3></span></div><!-- .pics_wrapper -->");
			$("#body").append("<div class=\"pics_wrapper\" id=\"wrapper_"+i+"\"><span class=\"gallery_name\"><a href=\"http://www.flickr.com/photos/53456090@N02/sets/"+set.id+"/show/\" target=\"_blank\"><h3>"+set.title._content+"</h3></a></span></div><!-- .pics_wrapper -->");
			
			// get pictures for photoset
			var pictures_url = "http://api.flickr.com/services/rest/?method=flickr.photosets.getPhotos&api_key=5d01332aa12fc3a028d37f20cc2d0659&photoset_id="+set.id+"&format=json&jsoncallback=?"
			$.getJSON(pictures_url,
			  function(data){
			    $.each(data.photoset.photo, function(j,item){
			      var photoURL = 'http://farm' + item.farm + '.static.flickr.com/' + item.server + '/' + item.id + '_' + item.secret + '_m.jpg';
						$("#wrapper_"+i).append("<div class=\"polaroid\"><img src=\""+photoURL+"\" alt=\"Picture\" /><p>&nbsp;"+item.title+"&nbsp;</p></div>");
			      if ( j == 6 ) return false; // get just 6 photos
			    }); // end each
					
					polaroidize();
			  }); // end getJSON pictures
			
			if ( i == 5 ) return false; // get just 6 sets TODO sets pagination
		}); // end each photoset
		
		//polaroidize();
		
	}); // end getJSON photosets

	//polaroidize();
	
	/*
	$.getJSON("http://api.flickr.com/services/feeds/photos_public.gne?id=86832359@N00&tags=julie&format=json&jsoncallback=?",
	  function(data){
			console.log(data);
	    $.each(data.items, function(i,item){
	      //$("<img/>").attr("src", item.media.m).appendTo("#flickr_pics");
				$(".pics_wrapper").append("<div class=\"polaroid\"><img src=\""+item.media.m+"\" alt=\"Picture\" /><p>&nbsp;"+item.title+"&nbsp;</p></div>");
	      if ( i == 5 ) return false;
	    });
			polaroidize();
	  });
	  */
	
}); // end jQuery
