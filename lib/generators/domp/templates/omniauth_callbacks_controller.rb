<% module_namespacing do -%>
class <%= class_name.pluralize %>::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def unlink_<%= class_name.downcase %>_authentication
    unless current_<%= class_name.downcase %>.nil?
      provider = AuthenticationProvider.find_by_name(params[:provider])
      authentication = provider.nil? ? nil : <%= class_name %>Authentication.where(uid: params[:uid], authentication_provider: provider)
      if authentication
        <%= class_name %>Authentication.destroy(authentication)
        flash[:success] = 'Your account has been unlinked from your ' + provider.name + ' account'
      end
    end
    # Change path to your own 'unlink' page
    redirect_to root_path
  end

  def create
    auth_params = request.env["omniauth.auth"]
    provider = AuthenticationProvider.where(name: auth_params.provider).first
    if provider.nil?
      redirect_to root_path, alert: 'Authentication provider is not supported'
    else
      authentication = provider.<%= class_name.downcase %>_authentications.where(uid: auth_params.uid).first
      existing_<%= class_name.downcase %> = current_<%= class_name.downcase %> || (authentication.nil? ? nil : <%= class_name %>.where(authentication.id).first)
      if authentication
        if !current_<%= class_name.downcase %>.nil? && current_<%= class_name.downcase %>.<%= class_name.downcase %>_authentications.include?(authentication)
          redirect_to root_url, alert: provider.name + ' account is already linked to your account'
        elsif !current_<%= class_name.downcase %>.nil? && found_user != current_<%= class_name.downcase %>
          redirect_to root_path, alert: provider.name + ' account is already in use'
        else
          sign_in_with_existing_authentication(authentication, provider)
        end
      elsif existing_<%= class_name.downcase %>
        create_authentication_and_sign_in(auth_params, existing_user, provider)
      else
        create_<%= class_name.downcase %>_and_authentication_and_sign_in(auth_params, provider)
      end
    end
  end

<% providers.each do |provider| -%>
  alias_method :<%= provider.underscore %>, :create
<% end -%>

  private

  def sign_in_with_existing_authentication(authentication, provider)
    flash[:success] = 'Succesfully signed in with ' + provider.name
    sign_in_and_redirect(:<%= class_name.downcase %>, authentication.<%= class_name.downcase %>)
  end

  def create_authentication_and_sign_in(auth_params, <%= class_name.downcase %>, provider)
    <%= class_name %>Authentication.create_from_omniauth(auth_params, <%= class_name.downcase %>, provider)
    if current_<%= class_name.downcase %>.nil?
      flash[:success] = 'Succesfully signed up with ' + provider.name
    else
      flash[:success] = 'Your account has been linked with ' + provider.name
    end
    sign_in_and_redirect(:<%= class_name.downcase %>, <%= class_name.downcase %>)
  end

  def create_<%= class_name.downcase %>_and_authentication_and_sign_in(auth_params, provider)
    <%= class_name.downcase %> = <%= class_name %>.create_from_omniauth(auth_params)
    if <%= class_name.downcase %>.valid?
      create_authentication_and_sign_in(auth_params, <%= class_name.downcase %>, provider)
    else
      flash[:alert] = <%= class_name.downcase %>.errors.full_messages.first
      redirect_to new_<%= class_name.downcase %>_registration_url
    end
  end

end
<% end -%>