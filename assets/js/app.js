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
Hooks.SortBy = {
  mounted() {
    this.handleEvent("saveSortByToLocalStorage", ({ sort_by }) => {
      localStorage.setItem("sort_by", sort_by);
    });
  },
};
// Horizontally-scrolling rail: arrow controls + a one-time "nudge" on load to
// signal that there's more content off-screen.
Hooks.ScrollRail = {
  mounted() {
    this.scroller = this.el.querySelector("[data-rail-scroll]");
    if (!this.scroller) return;

    this.prevBtn = this.el.querySelector("[data-rail-prev]");
    this.nextBtn = this.el.querySelector("[data-rail-next]");

    this.onScroll = () => this.updateArrows();
    this.scroller.addEventListener("scroll", this.onScroll, { passive: true });
    window.addEventListener("resize", this.onScroll);

    if (this.prevBtn)
      this.prevBtn.addEventListener("click", () => this.scrollByPage(-1));
    if (this.nextBtn)
      this.nextBtn.addEventListener("click", () => this.scrollByPage(1));

    this.updateArrows();
    this.maybeNudge();
  },
  destroyed() {
    if (this.scroller)
      this.scroller.removeEventListener("scroll", this.onScroll);
    window.removeEventListener("resize", this.onScroll);
  },
  scrollByPage(dir) {
    this.scroller.scrollBy({
      left: dir * this.scroller.clientWidth * 0.8,
      behavior: "smooth",
    });
  },
  updateArrows() {
    if (!this.prevBtn && !this.nextBtn) return;
    const { scrollLeft, scrollWidth, clientWidth } = this.scroller;
    const scrollable = scrollWidth > clientWidth + 1;
    const atStart = scrollLeft <= 1;
    const atEnd = scrollLeft + clientWidth >= scrollWidth - 1;
    if (this.prevBtn) this.prevBtn.disabled = !scrollable || atStart;
    if (this.nextBtn) this.nextBtn.disabled = !scrollable || atEnd;
  },
  maybeNudge() {
    const reduceMotion = window.matchMedia(
      "(prefers-reduced-motion: reduce)"
    ).matches;
    const scrollable =
      this.scroller.scrollWidth > this.scroller.clientWidth + 1;
    if (reduceMotion || !scrollable) return;

    // Fire once per full page load (re-fires on refresh, but not on in-page
    // LiveView navigation, where `window` persists).
    window.__railNudged = window.__railNudged || {};
    if (window.__railNudged[this.el.id]) return;
    window.__railNudged[this.el.id] = true;

    setTimeout(() => {
      this.scroller.scrollTo({
        left: this.scroller.clientWidth * 0.35,
        behavior: "smooth",
      });
      setTimeout(() => {
        this.scroller.scrollTo({ left: 0, behavior: "smooth" });
      }, 550);
    }, 450);
  },
};

let params = (node) => {
  var venueRestoreNode =
    node && node.querySelector("div[data-venue-filter-restore='true']");
  var dateRestoreNode =
    node && node.querySelector("div[data-date-filter-restore='true']");

  var venue_ids = null;
  var selected_date = null;
  var sort_by = localStorage.getItem("sort_by");

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
    sort_by: sort_by,
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
topbar.config({ barColors: { 0: "#fb7185" }, shadowColor: "rgba(0, 0, 0, .3)" });
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
