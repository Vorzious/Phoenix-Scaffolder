defmodule MixYyScaffold.Config do
  @moduledoc """
  Functions related to defining and updating user config.

  """

  @version "2.0.0"
  @default_template "git@github.com:weareyipyip/YipYip-Phoenix-Template.git"
  @usage "
  Something went wrong.

  Please run
        
      `$ mix yy.scaffold APP_NAME`
          
  to create a project using the default template.
        
  or run
        
      `$ mix yy.scaffold -h`
        
  for more information.
  "

  @version_check """

  YipYip Scaffold #{@version}
  """

  @help """
  $ mix yy.scaffold APP_NAME  #Create a project with the default template.
          
  Override Commands:
      -t <GitHub Repository Link> #Choose a GitHub repository to use as template
      -b <branch name>            #Choose a custom branch from the template repository
      -r <umbrella application>   #Choose what umbrella application you wish to remove, only supports 'api', 'cms' and 'web'
      -d <directory name>         #Choose a name for the root directory, has no influence on project name.
      -v                          #Shows the installed version of YipYip Scaffold
      -h                          #Shows help menu

  Command -r can receive multiple umbrella applications in a single string. Make sure to call it by splitting each umbrella application with a space.

  Example

  `$ mix yy.scaffold -r "api cms" APP_NAME`
  """

  @removal_web "
  You have decided to remove _web and all of its references, this will result in mandatory, manual edits.

  Please change your default reroute at

  `$ APP_NAME_umbrella/apps/APP_NAME_endpoint/lib/APP_NAME_endpoint/controllers/plugs/reroute.ex on line 14`

  And also please change your default error render at

  `$ APP_NAME_umbrella/apps/APP_NAME_endpoint/lib/APP_NAME_endpoint/views/error_view.ex`
  "

  @chars "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  @max String.length(@chars) - 1

  def default_config(name, overrides) do
    root = Path.rootname(System.version())

    %{
      APP_NAME: Map.get(overrides, :APP_NAME, name),
      MODULE_NAME: Map.get(overrides, :MODULE_NAME, Macro.camelize(name)),
      MIX_VERSION: Map.get(overrides, :MIX_VERSION, System.version()),
      MIX_VERSION_SHORT: Map.get(overrides, :MIX_VERSION_SHORT, root),
      SCAFFOLD_VERSION: Map.get(overrides, :SCAFFOLD_VERSION, constants.version),
      SECRET_KEY: Map.get(overrides, :SECRET_KEY, gen_secret_key_endpoint())
    }
  end

  def constants() do
    %{
      version: @version,
      version_check: @version_check,
      default_template: @default_template,
      usage: @usage,
      help: @help,
      removal_web: @removal_web
    }
  end

  defp gen_secret_key_endpoint() do
    Mix.shell().info([
      :light_blue,
      "Generating Secret Key.."
    ])

    # Generate a random key
    len(11) <> "+" <> len(9) <> "+" <> len(15) <> "/" <> len(11) <> "+" <> len(14)
  end

  defp len(len) do
    list = for _ <- :lists.seq(1, len), do: random_char()
    List.foldl(list, "", fn e, acc -> acc <> e end)
  end

  defp random_char() do
    key = Enum.random(0..@max)
    String.slice(@chars, key..key)
  end

  def apply_overrides(config, overrides) do
    Mix.shell().info([
      :light_blue,
      "Applying overrides.."
    ])

    Enum.each(overrides, fn {k, _} ->
      unless Enum.any?(config, &match?({^k, _}, &1)) do
        Mix.raise("Undefined parameter #{k}")
      end
    end)

    Enum.into(
      Enum.map(config, fn {k, v} ->
        {k, Map.get(overrides, k, v)}
      end),
      %{}
    )
  end
end
