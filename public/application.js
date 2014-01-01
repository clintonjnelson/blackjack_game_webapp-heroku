$(document).ready(function() {
  player_hits();
  player_stays();
});

// Updating page via Ajax for hit fuction
function player_hits() {
  $(document).on('click', '#hitbutton button', function(){
    $.ajax({
      type: 'POST',
      url: '/play/player/hit'
    }).done(function(msg){
      $('#play_container').replaceWith(msg);
    });
    return false;
  });
};

// Updating page via Ajax for stay function
function player_stays() {
  $(document).on('click', '#staybutton button', function() {
    $.ajax({
      type: 'POST',
      url: 'play/player/stay'
    }).done(function(msg){
      $('#play_container').replaceWith(msg);
    });
    return false;
  });
};





// $(document).ready(function() {
//   $('body').on('click', '#betform button', function() {
//     alert('Bet button clicked!');
//     return false;
//   });
// });


// $(document).ready(function() {
//   $(document).on('click', '#hitbutton button', function() {
//     alert('Hit button clicked!');
//     return false;
//   });
// });
