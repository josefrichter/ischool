/*
* Author:      Marco Kuiper (http://www.marcofolio.net/)
*/


function polaroidize() {
	
	// When everything has loaded, place all polaroids on a random position	
	$(".polaroid").each(function () {
    
		// randomize rotation degree for loaded pics
		var tempVal = Math.round(Math.random());
		if(tempVal == 1) {
			var rotDegrees = randomXToY(350, 360); // rotate left
		} else {
			var rotDegrees = randomXToY(0, 10); // rotate right
		}
		
		var position = $(this).parent().offset(); // top left corner position the of parent element
		var wiw = $(this).parent().width();
		var wih = $(this).parent().height();
		
		//var leftpos = Math.random()*(wiw - $(this).width()) + position.left;
		//var leftpos = Math.random()*(wiw - $(this).width());
		var leftpos = Math.random()*(wiw - 240);
		//var toppos = Math.random()*(wih - position.top) + position.top;
		//var toppos = Math.random()*(wih - $(this).height()) + position.top;
		var toppos = Math.random()*(wih - $(this).height());
		var toppos = Math.random()*(wih - 280);
		var cssObj = { 'left' : leftpos,
			'top' : toppos,
			'-webkit-transform' : 'rotate('+ rotDegrees +'deg)',  // safari only
			'-moz-transform' : 'rotate('+ rotDegrees +'deg)',  // firefox only
			'-o-transform' : 'rotate('+ rotDegrees +'deg)',  // opera only
			'tranform' : 'rotate('+ rotDegrees +'deg)' }; // added in case CSS3 is standard
		$(this).css(cssObj);
	});
	
	// Set the Z-Index (used to display images on top while dragging)
	var zindexnr = 1;
	
	// boolean to check if the user is dragging
	var dragging = false;
	
	// Show the polaroid on top when clicked on
	$(".polaroid").mouseup(function(e){
		if(!dragging) {
			// Bring polaroid to the foreground
			zindexnr++;
			/*
			var cssObj = { 'z-index' : zindexnr,
			'transform' : 'rotate(0deg)',	 // added in case CSS3 is standard
			'-moz-transform' : 'rotate(0deg)',  // firefox only
			'-webkit-transform' : 'rotate(0deg)',  // safari only
			'-o-transform' : 'rotate(0deg)' };  // opera only
			*/
			var cssOBJ = { 'z-index' : zindexnr };
			//$(this).css(cssObj);
			$(this).css('z-index',zindexnr);
		}
	});
	
	// Make the polaroid draggable & display a shadow when dragging
	$(".polaroid").draggable({
		containment: 'document',
		cursor: 'move',
		start: function(event, ui) {
			dragging = true;
			zindexnr++;
			/*
			var cssObj = { 'box-shadow' : '#888 3px 4px 4px', // added in case CSS3 is standard
				'-webkit-box-shadow' : '#888 3px 4px 4px', // safari only
				'-moz-box-shadow' : '#888 3px 4px 4px', // firefox only
				'padding-left' : '-4px',
				'padding-top' : '-4px',
				'z-index' : zindexnr };
			*/
			var cssObj = { 'z-index' : zindexnr }
			//$(this).css(cssObj);
			$(this).css('z-index',zindexnr);
		},
		stop: function(event, ui) {
			/*
			var tempVal = Math.round(Math.random());
			if(tempVal == 1) {
				var rotDegrees = randomXToY(330, 360); // rotate left
			} else {
				var rotDegrees = randomXToY(0, 30); // rotate right
			}
			var cssObj = { 'box-shadow' : '', // added in case CSS3 is standard
				'-webkit-box-shadow' : '', // safari only
				'-moz-box-shadow' : '', // firefox only
				'transform' : 'rotate('+ rotDegrees +'deg)', // added in case CSS3 is standard
				'-webkit-transform' : 'rotate('+ rotDegrees +'deg)', // safari only
				'-moz-transform' : 'rotate('+ rotDegrees +'deg)', // firefox only
				'margin-left' : '0px',
				'margin-top' : '0px' };
			$(this).css(cssObj);
			*/
			dragging = false;
		}
	});
} // end function polaroidize

// Function to get random number upto m
// http://roshanbh.com.np/2008/09/get-random-number-range-two-numbers-javascript.html
function randomXToY(minVal,maxVal,floatVal) {
	var randVal = minVal+(Math.random()*(maxVal-minVal));
	return typeof floatVal=='undefined'?Math.round(randVal):randVal.toFixed(floatVal);
}

