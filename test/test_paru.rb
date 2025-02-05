require "minitest/autorun"

require_relative "../lib/paru/pandoc.rb"
require_relative "../lib/paru/error.rb"

class ParuTest < MiniTest::Test

    def setup
    end

    def run_converter(converter, input_file, output_file, use_output_option = false)
        input = File.read(input_file)
        converted_input = converter << input
        output = File.read(output_file)
        
        if use_output_option
            converted_input = output
        end
        assert_equal output.strip, converted_input.strip
    end

    def test_custom_reader()
      converter = Paru::Pandoc.new do
        from "test/readers_writers/plain_reader.lua"
        to "markdown"
      end

      run_converter converter, "test/pandoc_input/simple_sentence.md", "test/pandoc_output/plain_sentence.md"
    end

    def test_custom_writer()
      converter = Paru::Pandoc.new do
        to "test/readers_writers/sample_html_writer.lua"
        from "markdown"
      end

      run_converter converter, "test/pandoc_input/simple_sentence.md", "test/pandoc_output/simple_sentence.html"
    end


    def test_info()
      info = Paru::Pandoc.info
      assert_match(/\d+\.\d+/, info[:version].join("."))
      if Gem.win_platform?
        assert_match(/\\pandoc$/, info[:data_dir])
      else
          major, minor = info[:version]
          if 2 <= major and 7 <= minor then
            assert_match(/\.local\/share\/pandoc$/, info[:data_dir])
          else
            assert_match(/\.pandoc$/, info[:data_dir])
          end
      end
    end

    def test_simple_conversion()
        converter = Paru::Pandoc.new do
            from "markdown"
            to "html"
        end

        run_converter converter, "test/pandoc_input/strong_hi.md", "test/pandoc_output/strong_hi.html"
    end

    def test_underscored()
        # Options with underscores following Ruby naming conventions
        converter = Paru::Pandoc.new do
            from "markdown"
            to "html"
            self_contained
            metadata "lang=en"
        end

        run_converter converter, "test/pandoc_input/hello.md", "test/pandoc_output/self_contained_hello.html"
    end

    def test_simple_conversion_with_spaces()
        converter = Paru::Pandoc.new do
            from "markdown"
            to "html"
            output "test/pandoc_output/strong hi.html"
        end

        run_converter converter, "test/pandoc_input/strong hi.md", "test/pandoc_output/strong hi.html", true
    end

    def test_with_bib()
        converter = Paru::Pandoc.new do
            from "markdown"
            to "html"
            bibliography "test/pandoc_input/bibliography.bib"
        end

        run_converter converter, "test/pandoc_input/simple_cite.md", "test/pandoc_output/simple_cite.html"
    end
    
    def test_with_bib_with_spaces()
        converter = Paru::Pandoc.new do
            from "markdown"
            to "html"
            bibliography "test/pandoc_input/my bibliography.bib"
        end

        run_converter converter, "test/pandoc_input/simple_cite.md", "test/pandoc_output/simple_cite.html"
    end

    def test_pandoc2yaml()
        require_relative '../lib/paru/pandoc2yaml'

        input = "test/pandoc_input/simple_yaml_metadata.md"
        output = File.read "test/pandoc_output/simple_yaml_metadata.yaml"

        result = Paru::Pandoc2Yaml.extract_metadata input
        assert_equal output, result
    end

    def test_convert_file()
        converter = Paru::Pandoc.new do
            from "markdown"
            to "html"
            bibliography "test/pandoc_input/my bibliography.bib"
        end

        output = converter.convert_file "test/pandoc_input/simple_cite.md"
        assert_equal output, File.read("test/pandoc_output/simple_cite.html") 
    end

    def test_throw_error_when_filter_crashes()
        converter = Paru::Pandoc.new do
            from "markdown"
            to "markdown"
            filter "./test/filters/crashing_filter.rb"
        end

        assert_raises Paru::Error do
            converter << "This is *a* string"
        end
    end

    def test_throw_error_when_bibliography_is_missing()
        converter = Paru::Pandoc.new do
            from "markdown"
            to "markdown"
            citeproc
            bibliography "some_non_existing_file.bib"
        end

        assert_raises Paru::Error do
            converter << "This is *a* string"
        end
    end

    # Running this test breaks `rake test`: run it manually
    def do_not_test_no_warning_after_stop()
        converter = Paru::Pandoc.new do
            from "markdown"
            to "markdown"
            filter "./test/filters/stop_warning.rb"
        end

        _, err = capture_io do
            converter << "Hello world"
        end

        assert_empty err
    end


    def test_nil_options()
      converter = Paru::Pandoc.new do
        from "markdown"
        to "html"
        filter nil
      end

      output = converter << "Hello *world*"

      assert_equal output, "<p>Hello <em>world</em></p>\n"
    end

    OPTION_PATTERN = /--[a-zA-Z-]+/m

    def test_paru_supports_all_options()
      # Collect pandoc's options via its "help" option
      converter = Paru::Pandoc.new do
        help
      end

      help_msg = converter << ""

      options = help_msg.scan OPTION_PATTERN

      # Each option should be an method on the converter. If not, fail this
      # test
      unsupported_options = []
      converter = Paru::Pandoc.new do |c|
        options.each do |option|
          method_name = option.delete_prefix("--").gsub("-", "_")
          begin
            c.send(method_name)
          rescue NameError => e
            unsupported_options << option
          end
        end 
      end

      assert_empty unsupported_options, "Paru does not support options: `#{unsupported_options.join(", ")}`"
    end

end
