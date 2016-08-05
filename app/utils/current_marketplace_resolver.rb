module CurrentMarketplaceResolver

  module_function

  def resolve_from_host(host, app_domain)
    Community.first
  end
end
