package bunnymarshal

import "github.com/sqlbunny/sqlbunny/schema"

type ModelMarshaler struct {
	Name         string
	Fields       []*schema.Field
	CustomFields []*MarshalerCustomField
	Loads        []*MarshalerLoad
}

type MarshalerLoad struct {
	Name string
}

type MarshalerCustomField struct {
	Name     string
	Type     schema.Type
	Nullable bool

	Tags schema.Tags

	Expr string
}

func (f *MarshalerCustomField) GoType() schema.GoType {
	if f.Nullable {
		return f.Type.(schema.NullableType).GoTypeNull()
	} else {
		return f.Type.GoType()
	}
}

func (f *MarshalerCustomField) GenerateTags() string {
	if _, ok := f.Tags["json"]; !ok {
		f.Tags["json"] = f.Name
		if f.Nullable {
			f.Tags["json"] += ",omitempty"
		}
	}
	return f.Tags.String()
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
