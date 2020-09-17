var images = document.getElementsByClassName("slider")[0].getElementsByTagName("img");
var title = document.getElementById("titleSlider");
var lstBtn = document.getElementsByClassName("slider")[0].getElementsByTagName("button");
var call = true;
function initSlider(){
    images[indexCurrent].style.opacity = 1;
    title.innerText = images[indexCurrent].getAttribute("title");
    if(showbutton == false){
        var lengthButton = lstBtn.length;
        for(i = 0; i < lengthButton; i++){
            lstBtn.item(0).remove();
        }
    }
    if(loop){
        setInterval(getNextImage, duration);
    }

}

function setImage(indexOld)
{
    
     for(i = 0; i < images.length; i++)
    {
         if(i != indexOld)
            images[i].style.opacity = 0;
    }
    var opacity = 0;
    var opacityImageOld = 1;
    var setOpacity =  setInterval(function (){
            
            images[indexCurrent].style.opacity = opacity;
            images[indexOld].style.opacity = opacityImageOld;
            title.innerText = images[indexCurrent].getAttribute("title");
            if(opacity >= 1 && opacityImageOld <= 0)
            {
                call = true;
                clearInterval(setOpacity);
                return;
            }
            opacity += 0.02;
            opacityImageOld -= 0.02;
            
    }, duration / 100);
    
}

function getNextImage(){

    if(call == false){
        return;
    }
    if(indexCurrent == images.length - 1)
    {
        indexCurrent = 0;
        setImage( images.length - 1);
    }
    else {
         
         indexCurrent++;
         setImage(indexCurrent - 1);
    }
    call = false;
}

function getPrevImage(){

    if(call == false){
        return;
    }
    if(indexCurrent == 0)
    {
        indexCurrent = images.length - 1;
        setImage( 0);
    }
    else {
         
         indexCurrent--;
         setImage(indexCurrent + 1);
    }
    call = false;
}



