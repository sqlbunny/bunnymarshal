package bunnymarshal

import "github.com/sqlbunny/sqlbunny/schema"

type ModelMarshaler struct {
	Name   string
	Fields []*schema.Field
}

type modelMarshalersExtKey struct{}

func ModelGetMarshalers(m *schema.Model) []*ModelMarshaler {
	r := m.GetExtension(modelMarshalersExtKey{})
	if r == nil {
		return nil
	}
	return r.([]*ModelMarshaler)
}

func ModelAddMarshaler(m *schema.Model, s *ModelMarshaler) {
	sers := ModelGetMarshalers(m)
	sers = append(sers, s)
	m.SetExtension(modelMarshalersExtKey{}, sers)
}
