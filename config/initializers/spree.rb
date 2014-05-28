# Configure Spree Preferences
#
# Note: Initializing preferences available within the Admin will overwrite any changes that were made through the user interface when you restart.
#       If you would like users to be able to update a setting with the Admin it should NOT be set here.
#
# In order to initialize a setting do:
# config.setting_name = 'new value'
Spree.config do |config|
  # Example:
  # Uncomment to override the default site name.
  config.site_name = "Bazaar Demo"
  config.logo = "logo.png"
  config.admin_interface_logo = "logo.png"
end

Spree.user_class = "Spree::User"
SpreeI18n::Config.available_locales = [:fa] # displayed on translation forms
SpreeI18n::Config.supported_locales = [:fa]
