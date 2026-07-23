package mcp_server

Alerts_Input :: struct {
  state: string,
}

Forecast_Input :: struct {
  latitude:  f64,
  longitude: f64,
}

Alert_Properties :: struct {
  event:       string,
  area_desc:   string,
  severity:    string,
  description: string,
  instruction: string,
}

Alert_Feature :: struct {
  properties: Alert_Properties,
}

Alerts_Response :: struct {
  features: []Alert_Feature,
}

Forecast_Period :: struct {
  name:              string,
  temperature:       int,
  temperature_unit:  string,
  wind_speed:        string,
  wind_direction:    string,
  detailed_forecast: string,
}

Forecast_Period_Properties :: struct {
  periods: []Forecast_Period,
}

Forecast_Response :: struct {
  properties: Forecast_Period_Properties,
}

Points_Forecast :: struct {
  forecast: string,
}

Points_Response :: struct {
  properties: Points_Forecast,
}

