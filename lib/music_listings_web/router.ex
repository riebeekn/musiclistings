defmodule MusicListingsWeb.Router do
  use MusicListingsWeb, :router
  use Honeybadger.Plug

  import MusicListingsWeb.UserAuth

  import Redirect

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MusicListingsWeb.Layouts, :root}
    plug :protect_from_forgery

    plug :put_secure_browser_headers, %{
      "content-security-policy" =>
        "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://challenges.cloudflare.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' wss: https:; frame-src https://challenges.cloudflare.com;"
    }

    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  redirect("/", "/events", :temporary)

  ## Public routes
  scope "/", MusicListingsWeb do
    pipe_through :browser

    live_session :current_user,
      on_mount: [{MusicListingsWeb.UserAuth, :mount_current_user}] do
      live "/events", EventLive.Index, :index
      live "/events/new", EventLive.New, :new
      live "/events/venue/:venue_id", VenueEventLive.Index, :index
      live "/venues", VenueLive.Index, :index
      live "/contact", ContactLive.New, :new
    end
  end

  ## Secured routes
  scope "/", MusicListingsWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{MusicListingsWeb.UserAuth, :mount_current_user}] do
      live "/submitted_events", SubmittedEventLive.Index, :index
      live "/venues/new", VenueLive.New, :new
    end
  end

  ## Authentication routes
  scope "/", MusicListingsWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{MusicListingsWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/log_in", UserLoginLive, :new
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", MusicListingsWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
  end

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
