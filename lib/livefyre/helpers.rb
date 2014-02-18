module Livefyre
  # Public: View helpers for Livefyre
  module Helpers

    # Public: Add a Livefyre comment form to this page.
    #
    # id      - [String, Integer] identifier to use for this conversation. Likely a post ID.
    # title   - [String] Title of this post or conversation
    # link    - [String] Link to this post or conversation
    # tags    - [Array, String] Optional array or comma-delimited list of tags on this conversation.
    # options - [Hash] Additional options to pass to the created div tag.
    #
    # Returns [String] div element for insertion into your view
    def livefyre_comments(id, title, link, tags = nil, options = {}, el = "livefyre_comments")
      meta = livefyre_conversation_metadata(id, title, link, tags, el)
      generate_content_tag(el, meta, options)
    end

    # Public: Add a Livefyre reviews form to this page.
    #
    # id      - [String, Integer] identifier to use for this conversation. Likely a post ID.
    # title   - [String] Title of this post or conversation
    # link    - [String] Link to this post or conversation
    # tags    - [Array, String] Optional array or comma-delimited list of tags on this conversation.
    # options - [Hash] Additional options to pass to the created div tag.
    #
    # Returns [String] div element for insertion into your view
    def livefyre_reviews(id, title, link, tags = nil, options = {}, el = "livefyre_reviews")
      meta = livefyre_conversation_metadata(id, title, link, tags, el, "reviews")
      generate_content_tag(el, meta, options, "reviews")
    end

    private

    # Internal: Generate a metadata hash from the given attributes.
    #
    # Returns [Hash]
    def livefyre_conversation_metadata(id, title, link, tags, el, type = nil)
      tags = tags.join(",") if tags.is_a? Array

      metadata = {
        :title => title,
        :url   => link,
        :tags  => tags
      }
      metadata[:checksum] = Digest::MD5.hexdigest(metadata.to_json)
      metadata[:articleId] = id
      metadata[:type] = type if type.present?
      post_meta = JWT.encode(metadata, Livefyre.config[:site_key])

      {
        :el => el,
        :checksum => metadata[:checksum],
        :collectionMeta => post_meta,
        :siteId => Livefyre.config[:site_id],
        :articleId => id.to_s
      }
    end

    # Internal: Generate a content tag with the given attributes.
    #
    # Returns [String]
    def generate_content_tag(el, meta, options, type = nil)
      options.merge!(
        :id => el,
        :data => {
          :checksum => meta[:checksum],
          :"collection-meta" => meta[:collectionMeta],
          :"site-id" => meta[:siteId],
          :"article-id" => meta[:articleId],
          :network => Livefyre.client.host,
          :root => Livefyre.config[:domain],
          :"post-to-buttons" => Livefyre.config[:postToButtons]
        }
      )
      options[:data].merge!(:app => type) if type.present?
      content_tag(:div, "", options)
    end
  end
end
