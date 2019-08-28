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
	{{range $field := $marshaler.CustomFields }}
	{{titleCase $field.Name}} {{goType $field.GoType}} `{{$field.GenerateTags}}`
	{{- end }}
}

func (o *{{$modelName}}) doMarshal{{$marshalerName}}(ctx context.Context) *{{$modelName}}Marshaled{{$marshalerName}} {
	return &{{$modelName}}Marshaled{{$marshalerName}}{
        {{range $field := $marshaler.Fields }}
        {{titleCase $field.Name}}: o.{{titleCase $field.Name}},
        {{- end }}
        {{range $field := $marshaler.CustomFields }}
        {{titleCase $field.Name}}: {{$field.Expr}},
        {{- end }}
	}
}

func (o *{{$modelName}}) Marshal{{$marshalerName}}(ctx context.Context) *{{$modelName}}Marshaled{{$marshalerName}} {
    if o == nil {
        return nil
    }

	{{range $load := $marshaler.Loads }}
	{{$modelNameCamel}}L{}.Load{{$load.Name | titleCase}}(ctx, true, o)
	{{- end }}

	// TODO load

	return o.doMarshal{{$marshalerName}}(ctx)
}


func (s {{$modelName}}Slice) Marshal{{$marshalerName}}(ctx context.Context) []*{{$modelName}}Marshaled{{$marshalerName}} {
	if s == nil {
		return nil
	}

	{{range $load := $marshaler.Loads }}
	{{$modelNameCamel}}L{}.Load{{$load.Name | titleCase}}(ctx, false, (*[]*{{$modelName}})(&s))
	{{- end }}

	res := make([]*{{$modelName}}Marshaled{{$marshalerName}}, len(s))
	for i, o := range s {
		res[i] = o.doMarshal{{$marshalerName}}(ctx)
	}
	return res
}

{{end}}

func (o *{{$modelName}}) Marshal(ctx context.Context, marshaler string) interface{} {
{{if .Marshalers}}
	switch marshaler {
{{range $marshaler := .Marshalers -}}
{{- $marshalerName := $marshaler.Name | titleCase -}}
		case "{{$marshaler.Name}}": return o.Marshal{{$marshalerName}}(ctx)
{{ end }}
		default:
			panic("Unknown marshaler for {{$modelName}}: " + marshaler)
	}
{{ else }}
	panic("Unknown marshaler for {{$modelName}}Slice: " + marshaler)
{{ end }}
}

func (s {{$modelName}}Slice) Marshal(ctx context.Context, marshaler string) interface{} {
{{if .Marshalers}}
	switch(marshaler) {
{{range $marshaler := .Marshalers -}}
{{- $marshalerName := $marshaler.Name | titleCase -}}
		case "{{$marshaler.Name}}": return s.Marshal{{$marshalerName}}(ctx)
{{ end }}
		default:
			panic("Unknown marshaler for {{$modelName}}Slice: " + marshaler)
	}
{{ else }}
	panic("Unknown marshaler for {{$modelName}}Slice: " + marshaler)
{{ end }}
}

{{range $marshaler := .Marshalers }}
{{- $marshalerName := $marshaler.Name | titleCase -}}

func (o *{{$modelName}}) ReverseMarshal{{$marshalerName}}(ctx context.Context, m *{{$modelName}}Marshaled{{$marshalerName}}) {
	{{range $field := $marshaler.Fields }}
	o.{{titleCase $field.Name}} = m.{{titleCase $field.Name}}
	{{- end }}
}
{{ end }}

func (o *{{$modelName}}) ReverseMarshal(ctx context.Context, m interface{}) {
{{if .Marshalers}}
	switch m := m.(type) {
{{range $marshaler := .Marshalers -}}
{{- $marshalerName := $marshaler.Name | titleCase -}}
		case *{{$modelName}}Marshaled{{$marshalerName}}: o.ReverseMarshal{{$marshalerName}}(ctx, m)
{{ end }}
		default:
			panic("Unknown reverse marshaler for {{$modelName}}")
	}
{{ else }}
	panic("Unknown reverse marshaler for {{$modelName}}")
{{ end }}
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
