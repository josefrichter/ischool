$(document).ready(function() {
  
  var pictures_url = "http://api.flickr.com/services/rest/?method=flickr.photosets.getPhotos&api_key=5d01332aa12fc3a028d37f20cc2d0659&photoset_id=72157629568724719&format=json&jsoncallback=?"
	$.getJSON(pictures_url,
	  function(data){
	    $.each(data.photoset.photo, function(j,item){
	      var photoURL = 'http://farm' + item.farm + '.static.flickr.com/' + item.server + '/' + item.id + '_' + item.secret + '.jpg';
				$(".pics_wrapper").append("<div class=\"polaroid\"><img src=\""+photoURL+"\" alt=\"Picture\" /><p>&nbsp;"+item.title+"&nbsp;</p></div>");
	      if ( j == 6000 ) return false; // get just 6 photos
	    }); // end each
			
			polaroidize();
	  }); // end getJSON pictures
	
}); // end jQuery
