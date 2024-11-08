// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken}
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
const addImage = async(url) => {
  try {
    const pathArray = window.location.pathname.split('/');
    number = pathArray[pathArray.length-1]
    const body = {
      image: {
        itemId: number,
        dataUrl: url
      }
    }

    const response = await fetch('/listingphoto', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json', 
        'X-CSRF-Token': csrfToken,        
      },
      body: JSON.stringify(body), // Only needed if sending data (e.g., POST)
    });

    console.log(response);
  } catch (error) {
    console.log(error)
  }
}

function readImage(ev){
ev.preventDefault();
let field = document.getElementById('upload-field');
let file = field.files[0];
console.log(file);

let rdr = new FileReader();

rdr.onload = function(ev){
let csrf = document.querySelector("meta[name='csrf-token']").getAttribute("content");

let dataURL = ev.target.result;

addImage(dataURL);

let img = document.getElementById('img1');
img.src = dataURL;

localStorage.setItem('saved-image', dataURL);
}
rdr.readAsDataURL(file);
}

document.getElementById('show-btn').addEventListener('click', readImage);

let dataURL = localStorage.getItem('saved-image');
if (dataURL) {
let img = document.getElementById('img1');
img.src = dataURL;
}

