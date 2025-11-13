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
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
// When you start using colocated hooks, uncomment the following line:
// import { hooks as colocatedHooks } from "phoenix-colocated/music_listings";

import topbar from "../vendor/topbar";
import { TurnstileHook } from "phoenix_turnstile";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

let Hooks = {};
Hooks.Turnstile = TurnstileHook;
Hooks.VenueFilter = {
  mounted() {
    this.handleEvent("saveVenueFilterIdsToLocalStorage", ({ venue_ids }) => {
      localStorage.setItem("venue_ids", venue_ids);
    });
    this.handleEvent("clearVenueFilterIdsFromLocalStorage", () => {
      localStorage.removeItem("venue_ids");
    });
  },
};
Hooks.DateFilter = {
  mounted() {
    this.handleEvent("saveDateFilterToLocalStorage", ({ selected_date }) => {
      localStorage.setItem("selected_date", selected_date);
    });
    this.handleEvent("clearDateFilterFromLocalStorage", () => {
      localStorage.removeItem("selected_date");
    });
  },
};

let params = (node) => {
  var venueRestoreNode =
    node && node.querySelector("div[data-venue-filter-restore='true']");
  var dateRestoreNode =
    node && node.querySelector("div[data-date-filter-restore='true']");

  var venue_ids = null;
  var selected_date = null;

  if (venueRestoreNode) {
    var venueKey = venueRestoreNode.getAttribute("data-storage-key");
    venue_ids = localStorage.getItem(venueKey);
  }

  if (dateRestoreNode) {
    var dateKey = dateRestoreNode.getAttribute("data-date-storage-key");
    selected_date = localStorage.getItem(dateKey);
  }

  return {
    _csrf_token: csrfToken,
    venue_ids: venue_ids,
    selected_date: selected_date,
  };
};

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: params,
  hooks: Hooks,
  // When using colocated hooks, merge them like this:
  // hooks: { ...Hooks, ...colocatedHooks },
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// js function to scroll to top on paging
window.addEventListener(
  "phoenix.link.click",
  function (event) {
    var scroll = event.target.getAttribute("data-scroll");
    if (scroll == "top") {
      window.scrollTo(0, 0);
    }
  },
  false
);

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
