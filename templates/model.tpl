{{- $dot := . -}}
{{- $modelNameSingular := .Model.Name | singular -}}
{{- $modelName := $modelNameSingular | titleCase -}}
{{- $modelNameCamel := $modelNameSingular | camelCase -}}


{{range $marshaler := .Marshalers }}

{{- $marshalerName := $marshaler.Name | titleCase -}}

type {{$modelName}}Marshaled{{$marshalerName}} struct {
	{{range $field := $marshaler.Fields }}
	{{titleCase $field.Name}} {{goType $field.GoType}} `{{$field.GenerateTags}}`
	{{- end }}
}

func (o *{{$modelName}}) Marshal{{$marshalerName}}() *{{$modelName}}Marshaled{{$marshalerName}} {
    if o == nil {
        return nil
    }
	return &{{$modelName}}Marshaled{{$marshalerName}}{
        {{range $field := $marshaler.Fields }}
        {{titleCase $field.Name}}: o.{{titleCase $field.Name}},
        {{- end }}
	}
}

func (o *{{$modelName}}) ReverseMarshal{{$marshalerName}}(m *{{$modelName}}Marshaled{{$marshalerName}}) {
	{{range $field := $marshaler.Fields }}
	o.{{titleCase $field.Name}} = m.{{titleCase $field.Name}}
	{{- end }}
}

func (s {{$modelName}}Slice) Marshal{{$marshalerName}}() []*{{$modelName}}Marshaled{{$marshalerName}} {
	if s == nil {
		return nil
	}

	res := make([]*{{$modelName}}Marshaled{{$marshalerName}}, len(s))
	for i, o := range s {
		res[i] = o.Marshal{{$marshalerName}}()
	}
	return res
}

{{end}}

func (o *{{$modelName}}) Marshal(marshaler string) interface{} {
	switch marshaler {
{{range $marshaler := .Marshalers -}}
{{- $marshalerName := $marshaler.Name | titleCase -}}
		case "{{$marshaler.Name}}": return o.Marshal{{$marshalerName}}()
{{ end }}
		default:
			panic("Unknown marshaler for {{$modelName}}: " + marshaler)
	}
}

func (o *{{$modelName}}) ReverseMarshal(m interface{}) {
	switch m := m.(type) {
{{range $marshaler := .Marshalers -}}
{{- $marshalerName := $marshaler.Name | titleCase -}}
		case *{{$modelName}}Marshaled{{$marshalerName}}: o.ReverseMarshal{{$marshalerName}}(m)
{{ end }}
		default:
			panic("Unknown reverse marshaler for {{$modelName}}")
	}
}

func (s {{$modelName}}Slice) Marshal(marshaler string) interface{} {
	switch(marshaler) {
{{range $marshaler := .Marshalers -}}
{{- $marshalerName := $marshaler.Name | titleCase -}}
		case "{{$marshaler.Name}}": return s.Marshal{{$marshalerName}}()
{{ end }}
		default:
			panic("Unknown marshaler for {{$modelName}}Slice: " + marshaler)
	}
}

{{ if .PoisonMarshalJSON }}
func (o *{{$modelName}}) MarshalJSON() ([]byte, error) {
    panic("Model instances must not be JSON marshaled directly. Go through a marshaler instead")
}
{{ end }}
func (o *{{$modelName}}) PrimaryKeyColumns() ([]string) {
	return {{$modelNameCamel}}PrimaryKeyColumns
}

func (o {{$modelName}}Slice) PrimaryKeyColumns() ([]string) {
	return {{$modelNameCamel}}PrimaryKeyColumns
}
