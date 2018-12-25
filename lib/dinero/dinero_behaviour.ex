defmodule Dinero.DineroApiBehaviour do
  @type method :: :get | :post | :put | :patch | :delete | :options | :head
  @type headers :: [{atom, binary}] | [{binary, binary}] | %{binary => binary} | any
  @type url :: binary | any
  @type body :: binary | charlist | iodata | {:form, [{atom, any}]} | {:file, binary} | any
  @type params :: map | keyword | [{binary, binary}] | any
  @type options :: keyword | any

  @callback authentication(binary, binary, binary) :: {:ok, any} | {:error, Error.t()}
  @callback get_contacts(integer, binary, params) ::
              {:ok, Response.t() | AsyncResponse.t()} | {:error, Error.t()}
  @callback create_contact(integer, binary, any) :: {:ok, map} | {:error, Error.t()}
  @callback create_invoice(integer, binary, map) :: {:ok, map} | {:error, Error.t()}
end
