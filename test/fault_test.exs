defmodule ExOnvif.FaultTest do
  use ExUnit.Case, async: true

  alias ExOnvif.Fault
  alias ExOnvif.Fault.Code
  alias ExOnvif.Fault.SubCode

  test "parses a SOAP fault with nested subcodes and detail" do
    xml = File.read!("test/fixtures/soap_fault.xml")

    assert {:ok, fault} = Fault.parse(xml)

    assert fault == %Fault{
             code: %Code{
               value: "env:Sender",
               subcode: %SubCode{
                 value: "ter:InvalidArgVal",
                 subcode: %SubCode{value: "ter:NoProfile", subcode: nil}
               }
             },
             reason: "Argument Value Invalid",
             detail: %{
               "ter:Fault" => %{
                 "ter:Code" => "InvalidArgVal",
                 "ter:Subcode" => "NoProfile",
                 "ter:Reason" => "No such profile",
                 "ter:Description" => "The requested profile does not exist"
               }
             }
           }
  end

  test "parses a SOAP fault without subcode and without detail" do
    xml = """
    <?xml version="1.0" encoding="UTF-8"?>
    <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope">
      <SOAP-ENV:Body>
        <SOAP-ENV:Fault>
          <SOAP-ENV:Code>
            <SOAP-ENV:Value>env:Receiver</SOAP-ENV:Value>
          </SOAP-ENV:Code>
          <SOAP-ENV:Reason>
            <SOAP-ENV:Text xml:lang="en">Internal Error</SOAP-ENV:Text>
          </SOAP-ENV:Reason>
        </SOAP-ENV:Fault>
      </SOAP-ENV:Body>
    </SOAP-ENV:Envelope>
    """

    assert {:ok, fault} = Fault.parse(xml)

    assert fault == %Fault{
             code: %Code{value: "env:Receiver", subcode: nil},
             reason: "Internal Error",
             detail: nil
           }
  end

  test "returns error when body is not a fault" do
    xml = File.read!("test/fixtures/get_device_information.xml")
    assert {:error, :parse_error} = Fault.parse(xml)
  end

  test "returns error on invalid XML" do
    assert {:error, :parse_error} = Fault.parse("not xml at all")
  end

  test "api client returns parsed fault on HTTP 400" do
    xml = File.read!("test/fixtures/soap_fault.xml")
    device = ExOnvif.Factory.device()

    Mimic.expect(Tesla, :request, fn _client, _opts ->
      {:ok, %{status: 400, body: xml}}
    end)

    assert {:error, fault} = ExOnvif.Devices.get_device_information(device)

    assert fault.code.value == "env:Sender"
    assert fault.code.subcode.value == "ter:InvalidArgVal"
    assert fault.code.subcode.subcode.value == "ter:NoProfile"
    assert fault.reason == "Argument Value Invalid"
    assert get_in(fault, [Access.key(:detail), "ter:Fault", "ter:Code"]) == "InvalidArgVal"
  end
end
