defmodule PhoenixDSK.Router do
  use PhoenixDSK.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PhoenixDSK do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index

    get "/dsks", DskController, :index

    get "/users", UserController, :index
    # Why the @ sign in the following? It's a userId that cannot exist in Learn.
    get "/users/user@id", UserController, :select
    get "/users/:userName", UserController, :show

    post "/users/:userName", UserController, :update

    get "/courses", CourseController, :index
    # Why course@id in the following? Learn doesn't allow @ in an ID, hence
    # course@id is not an ID for a course on the system.
    get "/courses/course@id", CourseController, :select
    get "/courses/:courseId", CourseController, :show

    post "/courses/:courseId", CourseController, :update

    get "/memberships", MembershipsController, :index
    # For nested see:
    # https://elixirforum.com/t/how-to-render-a-template-inside-a-web-templates-folder-subfolder/1404/6
    # We have to mod web.ex
    get "/memberships/courseId", MembershipsController, :select
    get "/memberships/courseId/:courseId", MembershipsController, :show

    # 2017.12.12 redesign - the link on the page for the membership will
    # link to a show for the membership, then we add a post for that.
    # So, we shouldn't need the following:
    #post "/memberships/:courseId/:userName", MembershipController, :update

    # Keep the following around to demonstrate Phoenix hot code reloading!
    get "/hello", HelloController, :index
    # From: http://www.phoenixframework.org/docs/adding-pages
    # Notice that we put the atom :userName in the path. Phoenix will take
    # whatever value that appears in that position in the URL and pass a Map
    # with the key userName pointing to that value to the controller.
    # For example, if we point the browser at:
    # http://localhost:4000/hello/jdoe, the value of
    # :userName" will be "jdoe".
    get "/hello/:userName", HelloController, :show

  end

  # Other scopes may use custom stacks.
  # scope "/api", PhoenixDSK do
  #   pipe_through :api
  # end
end
