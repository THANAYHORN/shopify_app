# frozen_string_literal: true
module ShopifyApp
  module ShopSessionStorage
    extend ActiveSupport::Concern
    include ::ShopifyApp::SessionStorage

    included do
      validates :shopify_domain, presence: true, uniqueness: { case_sensitive: false }
    end

    class_methods do
      def store(auth_session, *_args)
        shop = find_or_initialize_by(shopify_domain: auth_session.domain)
        shop.shopify_token = auth_session.token

        if ActiveRecord::Base.connection.column_exists?(:shops, :scopes)
          shop.scopes = auth_session.extra[:scopes]
        end

        shop.save!
        shop.id
      end

      def retrieve(id)
        shop = find_by(id: id)
        construct_session(shop)
      end

      def retrieve_by_shopify_domain(domain)
        shop = find_by(shopify_domain: domain)
        construct_session(shop)
      end

      private

      def shop_scopes(shop)
        shop.scopes
      rescue
        nil
      end

      def construct_session(shop)
        return unless shop

        ShopifyAPI::Session.new(
          domain: shop.shopify_domain,
          token: shop.shopify_token,
          api_version: shop.api_version,
          extra: { scopes: shop_scopes(shop) }
        )
      end
    end
  end
end
