# frozen_string_literal: true

module AllureRspec
  # RSpec custom tag parser
  module TagParser
    # Get custom labels
    # @param [Hash] metadata
    # @return [Array<Allure::Label>]
    def tag_labels(metadata)
      return [] unless metadata.keys.any? { |k| allure?(k) }

      metadata.select { |k| allure?(k) }.values.map { |v| Allure::ResultUtils.tag_label(v) }
    end
    
    # Set package from from filename, original from folder
    # @param [Hash] metadata
    # @return [String]
    def set_package(example)
      Allure::ResultUtils.package_label(File.basename(example.file_path, ".rb"))
      # Allure::ResultUtils.package_label(Pathname.new(strip_relative(example.file_path)).parent.to_s)
    end

    # Set feature from tag or use example description
    # @param [Hash] metadata
    # @return [String]
    def set_feature(example)
      Allure::ResultUtils.feature_label(example.metadata[:feature] || example.example_group.description)
    end

    # Set story from tag or use example description
    # @param [Hash] metadata
    # @return [String]
    def set_story(example)
      Allure::ResultUtils.story_label(example.metadata[:story] || example.description)
    end

    # Get tms links
    # @param [Hash] metadata
    # @return [Array<Allure::Link>]
    def tms_links(metadata)
      matching_links(metadata, :tms)
    end

    # Get issue links
    # @param [Hash] metadata
    # @return [Array<Allure::Link>]
    def issue_links(metadata)
      matching_links(metadata, :issue)
    end

    # Get severity
    # @param [Hash] metadata
    # @return [String]
    def severity(metadata)
      Allure::ResultUtils.severity_label(metadata[:severity] || "normal")
    end

    # Get test_type
    # @param [Hash] metadata
    # @return [String]
    def test_type_labels(metadata)
      return [] unless metadata.keys.any? { |k| test_type?(k) }

      metadata.select { |k, _v| test_type?(k) }.values.map { |v| Allure::ResultUtils.test_type_label(v) }
    end
    
    # Get status details
    # @param [Hash] metadata
    # @return [Hash<Symbol, Boolean>]
    def status_detail_tags(metadata)
      {
        flaky: !metadata[:flaky].nil?,
        muted: !metadata[:muted].nil?,
        known: !metadata[:known].nil?
      }
    end

    private

    # @param [Hash] metadata
    # @param [Symbol] type
    # @return [Array<Allure::Link>]
    def matching_links(metadata, type)
      unless AllureRspec.configuration.public_send("link_#{type}_pattern") &&
             metadata.keys.any? { |k| __send__("#{type}?", k) }
        return []
      end

      metadata
        .select { |k| __send__("#{type}?", k) }.values
        .map { |v| Allure::ResultUtils.public_send("#{type}_link", v) }
    end

    # Does key match custom allure label
    # @param [Symbol] key
    # @return [boolean]
    def allure?(key)
      key.to_s.match?(/allure(_\d+)?/i)
    end

    # Does key match tms pattern
    # @param [Symbol] key
    # @return [boolean]
    def tms?(key)
      key.to_s.match?(/tms(_\d+)?/i)
    end

    # Does key match issue pattern
    # @param [Symbol] key
    # @return [boolean]
    def issue?(key)
      key.to_s.match?(/issue(_\d+)?/i)
    end
    
    # Does key match test type pattern
    # @param [Symbol] key
    # @return [boolean]
    def test_type?(key)
      key.to_s.match?(/test_type/i)
    end
  end
end
