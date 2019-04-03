defmodule PhoenixViewAssets do
  @doc false

  @manifest_file "priv/manifest.json"
  @views_path "assets/views"

  defmacro __using__(_opts) do
    app_module = __CALLER__.module

    {app_view_assets, app_default_styles, app_default_scripts} = get_assets(app_module)

    head_ast =
      quote do
        defmacro __using__(_opts) do
          assets_module = unquote(app_module)

          quote do
            def styles(conn) do
              unquote(assets_module).styles(conn)
            end

            def scripts(conn) do
              unquote(assets_module).scripts(conn)
            end
          end
        end
      end

    head_ast |> Macro.to_string() |> Code.format_string!()

    app_view_assets_ast =
      app_view_assets
      |> Enum.map(fn {view_module, view_template, {styles, scripts}} ->
        quote do
          def styles(%Plug.Conn{
                private: %{
                  phoenix_view: unquote(view_module),
                  phoenix_template: unquote(view_template)
                }
              }) do
            unquote(Enum.map(styles, &("/" <> &1)))
          end

          def scripts(%Plug.Conn{
                private: %{
                  phoenix_view: unquote(view_module),
                  phoenix_template: unquote(view_template)
                }
              }) do
            unquote(Enum.map(scripts, &("/" <> &1)))
          end
        end
      end)

    default_ast =
      quote do
        def styles(%Plug.Conn{private: %{phoenix_view: view_module}}) do
          unquote(Enum.map(app_default_styles, &("/" <> &1)))
        end

        def scripts(%Plug.Conn{private: %{phoenix_view: view_module}}) do
          unquote(Enum.map(app_default_scripts, &("/" <> &1)))
        end

        @doc """
        Returns true whenever the assets manifest changes in the filesystem.
        """
        def __phoenix_recompile__? do
          unquote(manifest_hash()) != unquote(__MODULE__).manifest_hash()
        end
      end

    [
      head_ast,
      app_view_assets_ast,
      default_ast
    ]
  end

  defp get_assets(module) do
    root_module = get_root_module(module)
    views = overrided_views(@views_path, root_module)

    manifest =
      read_manifest()
      |> Jason.decode!()

    view_assets = get_assets(views, manifest)
    default_styles = manifest_assets(manifest, ".css", "default")
    default_scripts = manifest_assets(manifest, ".js", "default")
    {view_assets, default_styles, default_scripts}
  end

  defp read_manifest do
    @manifest_file
    |> File.read()
    |> case do
      {:ok, body} ->
        body

      {:error, _} ->
        IO.warn("Asset manifest file (#{@manifest_file}) not found. Build assets first.")
        "{}"
    end
  end

  def manifest_hash do
    read_manifest()
    |> :erlang.md5()
  end

  defp get_root_module(module) do
    [_, web_module | _] =
      module
      |> Atom.to_string()
      |> String.split(".")

    "Elixir.#{web_module}" |> String.to_atom()
  end

  defp get_assets(views, manifest) do
    views
    |> Enum.map(fn {view_module, view_name, template_name} ->
      view_template = "#{template_name}.html"

      styles = manifest_assets(manifest, ".css", view_name, template_name)
      scripts = manifest_assets(manifest, ".js", view_name, template_name)

      {view_module, view_template, {styles, scripts}}
    end)
  end

  defp overrided_views(root_path, root_module, view_name_parent \\ "") do
    File.ls!(root_path)
    |> Enum.flat_map(fn view_name ->
      view_path = Path.join(root_path, view_name)

      if File.dir?(view_path) do
        File.ls!(view_path)
        |> Enum.flat_map(fn file ->
          cond do
            Path.extname(file) == ".js" ->
              template_path = Path.join(view_path, file)

              unless File.dir?(template_path) do
                template_name = Path.basename(file, ".js")
                view_module = String.to_atom("#{root_module}.#{Macro.camelize(view_name)}View")

                [{view_module, view_name_parent <> view_name, template_name}]
              end

            File.dir?(Path.join(view_path, file)) ->
              new_module = String.to_atom("#{root_module}.#{Macro.camelize(view_name)}")
              overrided_views(view_path, new_module, view_name <> "-")
          end
        end)
      else
        []
      end
    end)
  end

  defp manifest_assets(manifest, extension, view_name, template_name) do
    manifest_assets(manifest, extension, "#{view_name}-#{template_name}")
  end

  defp manifest_assets(manifest, extension, asset_name) do
    manifest
    |> Enum.filter(fn {name, file} ->
      Path.extname(file) == extension &&
        (String.contains?(name, "~#{asset_name}~") ||
           String.contains?(name, "~#{asset_name}.") ||
           String.starts_with?(name, "#{asset_name}."))
    end)
    |> Enum.map(fn {_, file} -> file end)
    |> Enum.sort()
  end
end
