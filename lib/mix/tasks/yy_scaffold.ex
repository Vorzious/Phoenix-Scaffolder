defmodule Mix.Tasks.Yy.Scaffold do
  @shortdoc "Generates a full Phoenix project from a Git Repository."
  @moduledoc """
  Generates a full Phoenix project from a Github Repository.

    $ mix yy.scaffold <project name>
  to create a phoenix project using default settings.

  The following arguments are available to override
  the default settings to custom ones, every argument
  is indepedentent.

  -t <github link>
  overrides what template to use. For example you can
  run $ mix yy.scaffold -t git@github.com:useer/repo.git app_name
  to get a custom template and name it "app_name".

  -b <branch>
  overrides what git branch you use. Default branch is master.
  For example you can run $ mix yy.scaffold -b develop app_name
  to get the custom template from the develop branch.

  -d <directory name>
  overrides the root directory to a different name than the project name.
  For example you can run $ mix yy.scaffold -d 0000-project-name my_project
  to get the root folder to be named '0000-project-name' while the application will be called
  'my_project'

  -h
  This will show the help menu and wil not run anything else.


  For the following example the application name that we will use is
  yip_yip_phoenix_application and will be generated with:

    $ mix yy.scaffold yip_yip_phoenix_application

  Overall, this generator will replace the following variables
  inside the template to the given app_name argument.

    {{APP_NAME}}                    => "yip_yip_phoenix_application"
    {{MODULE_NAME}}             => "YipYipPhoenixApplication"
    {{MIX_VERSION}}               => "1.6"
    {{MIX_VERSION_SHORT}}  => "1.6.2"
    {{SCAFFOLD_VERSION}}     => "0.0.1"

  These variables are crucial to the scaffolder and is required to make
  the templates work. 
  """
  use Mix.Task

  require Logger

  def run(args) do
    options = [
      strict: [
        template: :string,
        branch: :string,
        remove: :string,
        destination: :string,
        help: :string,
        version: :string
      ],
      aliases: [t: :template, b: :branch, r: :remove, d: :destination, h: :help, v: :version]
    ]

    heads = OptionParser.parse_head(args, options)

    # Help Function
    if(Enum.member?(args, "-h")) do
      Mix.shell().info([
        :light_yellow,
        "YipYip Scaffold Help Menu"
      ])

      Mix.shell().info([
        :white,
        MixYyScaffold.Config.constants().help
      ])

      System.halt(1)
    end

    # End Help

    # Version Function
    if(Enum.member?(args, "-v")) do
      Mix.shell().info([
        :light_blue,
        MixYyScaffold.Config.constants().version_check
      ])

      System.halt(1)
    end

    # End Version

    {name, template, branch, remove, destination, overrides, rest} =
      case heads do
        {opts, [name | rest], []} ->
          name = MixYyScaffold.Utils.parse_name(name)

          template =
            Keyword.get(opts, :template, MixYyScaffold.Config.constants().default_template)

          branch = Keyword.get(opts, :branch, "master")
          remove = Keyword.get(opts, :remove, "")
          destination = Keyword.get(opts, :destination, name)
          overrides = Keyword.drop(opts, [:template, :branch, :remove, :destination])

          {name, template, branch, remove, destination, overrides, rest}

        {_, _, [{opt, _}]} ->
          Mix.raise("Undefined option #{opt}, #{MixYyScaffold.Config.constants().usage}")

        {_, [], _} ->
          Mix.raise("#{MixYyScaffold.Config.constants().usage}")
      end

    if(File.exists?(name)) do
      Mix.raise("Project path ./#{name} already exists")
    end

    # Start build
    Mix.shell().info([
      :light_yellow,
      "Starting YipYip Scaffolding..."
    ])

    # Get template from  link
    fetched_template = fetch_template(template, branch, destination)
    parsed_overrides = parse_overrides(overrides)

    instantiate_template(name, fetched_template, parsed_overrides, rest)

    # Remove umbrella applications
    if(Enum.member?(args, "-r")) do
      remove
      |> String.split(" ")
      |> removal_arguments(name)
    end

    cleanup()

    # If success
    Mix.shell().info([
      :light_green,
      "Successfully built ",
      :light_blue,
      name,
      :light_green,
      " from ",
      :light_blue,
      template,
      :light_green,
      ", from branch: ",
      :light_blue,
      branch,
      :light_green,
      "."
    ])

    # End
    Mix.shell().info([
      :light_yellow,
      "Thank you for using YipYip Scaffolding."
    ])
  end

  # Guard for if a valid template
  # $ mix yy.scaffold
  defp fetch_template(template, branch, dest) do
    Mix.shell().info([
      :light_blue,
      "Fetching Template.."
    ])

    # Check if template link is a git repository
    is_git = String.ends_with?(template, ".git") or File.dir?(Path.join([template, ".git"]))

    cond do
      is_git ->
        # git checkout
        Mix.SCM.Git.checkout(git: template, branch: branch, checkout: dest)

      File.dir?(template) ->
        File.cp_r!(template, dest)
    end

    dest
  end

  # $ mix yy.scaffold
  # overrides get parsed
  defp parse_overrides(overrides) do
    overrides =
      Enum.map(overrides, fn str ->
        [opt_name, value] = String.split(str, "=")
        param_name = String.to_atom(opt_name)
        {param_name, value}
      end)

    Enum.into(overrides, %{})
  end

  defp instantiate_template(name, path, overrides, rest_args) do
    config = MixYyScaffold.Config.default_config(name, overrides)

    File.cd!(path)
    {config, flags} = MixYyScaffold.Eval.eval_defs(config, overrides, rest_args)
    actions = MixYyScaffold.Eval.eval_init(config, flags)
    substitute_directories(1, config, actions)
  end

  def substitute_directories(x, user_config, actions) do
    {files, template_files, directories} = get_files_and_directories()

    processed_directories =
      directories
      |> Enum.filter(&(Enum.count(Path.split(&1)) == x))
      |> substitute_variables(user_config)

    if Enum.empty?(processed_directories) do
      postprocess_files(files, user_config, template_files, actions)
    else
      substitute_directories(x + 1, user_config, actions)
    end
  end

  defp postprocess_files(files, user_config, template_files, actions) do
    files
    |> reject_auxilary_files
    |> substitute_variables(user_config)
    |> substitute_variables_in_files(user_config)

    postprocess_template_files(template_files, user_config, actions)
  end

  defp postprocess_template_files(paths, user_config, actions),
    do: Enum.reduce(actions, paths, &process_action(&1, &2, user_config))

  defp process_action({:select, template, rename}, paths, config) do
    new_name = substitute_variables_in_string(rename, config)

    if path = Enum.find(paths, &(&1 == template <> "._template")) do
      new_path = Path.join([Path.dirname(path), new_name])
      :ok = :file.rename(path, new_path)
      List.delete(paths, path)
    else
      Mix.raise("Template file '#{template <> "._template"}' not found")
    end
  end

  # Returns all files and directories that were found in the template link
  defp get_files_and_directories() do
    {files, dirs} = Enum.partition(Path.wildcard("**"), &File.regular?/1)
    template_files = Enum.filter(files, &String.ends_with?(&1, "._template"))
    {files, template_files, dirs}
  end

  defp reject_auxilary_files(paths) do
    Enum.reject(paths, &String.starts_with?(&1, "_template_config"))
  end

  #
  # Replaces variables
  # {{APP_NAME}}
  # {{MODULE_NAME}}
  #
  defp substitute_variables(paths, config) do
    paths
    |> Enum.map(fn path ->
      new_path = substitute_variables_in_string(path, config)

      if path != new_path do
        case :file.rename(path, new_path) do
          :ok -> :ok
          {:error, errCode} -> {:error, errCode}
        end
      end

      new_path
    end)
  end

  defp substitute_variables_in_string(string, config) do
    Enum.reduce(config, string, fn {k, v}, string ->
      String.replace(string, "{{#{k}}}", v)
    end)
  end

  defp substitute_variables_in_files(files, config) do
    files
    |> Enum.each(fn path ->
      new_contents =
        path
        |> File.read!()
        |> substitute_variables_in_string(config)

      File.write!(path, new_contents)
    end)
  end

  # End Replace

  # Check removal arguments
  defp removal_arguments(removals, name) do
    Mix.shell().info([
      :light_blue,
      "Removing unwanted umbrella apps.."
    ])

    Enum.each(removals, fn i -> remove_applications(i, name) end)
  end

  # Remove subfolders and references
  defp remove_applications(removal, name) do
    removal_string =
      case removal do
        "api" ->
          remove_directories("#{name}_umbrella/apps/#{name}_api")
          "#YipYip-Scaffold-Remove-API"

        "cms" ->
          remove_directories("#{name}_umbrella/apps/#{name}_cms")
          "#YipYip-Scaffold-Remove-CMS"

        "web" ->
          remove_directories("#{name}_umbrella/apps/#{name}_web")

          Mix.shell().info([
            :light_yellow,
            MixYyScaffold.Config.constants().removal_web
          ])

          "#YipYip-Scaffold-Remove-WEB"

        _ ->
          Mix.raise("#{removal} is not supported. Please only use 'api', 'cms' or 'web'.")
      end

    {files_to_edit, _template_files, _dirs} = get_files_and_directories()
    Enum.each(files_to_edit, fn i -> edit_references(i, removal_string) end)
  end

  defp remove_directories(directory), do: File.rm_rf(directory)

  defp edit_references(filename, app) do
    newFile =
      File.stream!(filename)
      |> Enum.filter(fn contents ->
        !String.ends_with?(contents, app <> "\n")
      end)

    File.write(filename, newFile)
  end

  defp cleanup() do
    Mix.shell().info([
      :light_blue,
      "Cleaning Project"
    ])

    [".git"] |> Enum.each(&File.rm_rf/1)
  end
end
