# ExOnvif

[![Hex.pm](https://img.shields.io/hexpm/v/ex_onvif.svg)](https://hex.pm/packages/ex_onvif)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/ex_onvif)

*Originally forked from https://github.com/hammeraj/onvif*

Elixir interface for Onvif functions.

## Installation

The package can be installed by adding `onvif` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_onvif, "~> 0,7.1"}
  ]
end
```

## How to use

This library provides an interface for an Elixir application to make requests to Onvif compliant devices.

A request requires a `Device` struct which contains data necessary to successfully make the request, including
an address, username, password, a best guess at which authentication method will work, and paths for several
onvif services, include Media and Device services. 

An Onvif compliant device should implement functions outlined in Onvif documentation, depending on which profiles with which the 
device claims to be compliant. That said, a disclaimer that nothing is guaranteed and devices may not respond to requests for 
services that should be implemented.

To start, make a probe request:
```elixir
> ExOnvif.Discovery.probe()
[
  %ExOnvif.Discovery.Probe{
    address: ...
  }
]
```

This will return a list of devices on the network that respond to Web Services Dynamic Discovery. The request
_should_ filter any non-video device but it is possibly that printers, etc. will show up and will need to be
filtered by application logic. If you already have information about the device, you can use:

```elixir
> ExOnvif.Discovery.probe_by(ip_address: "127.0.0.1")
%ExOnvif.Discovery.Probe{
  address: [...],
  device_ip: "127.0.0.1",
  ...
}
```
More details in the `ExOnvif.Discovery.probe_by/1` docs.

Once you have a valid `Probe` struct, you can initialize a device.

```elixir
> ExOnvif.Device.init(probe, username, password)
%ExOnvif.Device{
  ...
}
```