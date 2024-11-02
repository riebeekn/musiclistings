defmodule MusicListingsWeb.Router do
  use MusicListingsWeb, :router

  import Redirect

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MusicListingsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  redirect("/", "/events", :temporary)

  scope "/", MusicListingsWeb do
    pipe_through :browser

    live "/events", EventLive.Index, :index
    live "/events/new", EventLive.New, :new
    live "/events/venue/:venue_id", VenueEventLive.Index, :index
    live "/venues", VenueLive.Index, :index
    live "/contact", ContactLive.New, :new
  end

  # Other scopes may use custom stacks.
  # scope "/api", MusicListingsWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:music_listings, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MusicListingsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
      forward("/gallery", MusicListings.Emails.Gallery)
    end
  end
end
