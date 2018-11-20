defmodule JobplannerDinero.Auth.Authorizer do
  def can_manage?(user, business_id) do
    user && !!Enum.find(user.businesses, false, fn b -> b.id == business_id end)
  end
end
