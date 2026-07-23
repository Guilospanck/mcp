package mcp_sdk

import data_layer "data_layer"
import transport_layer "transport_layer"


main :: proc() {

  data_layer.test_data_layer()
  transport_layer.test_transport_layer()

}

