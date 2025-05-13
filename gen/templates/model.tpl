{{- $dot := . -}}
{{- $modelNameSingular := .Model.Name | singular -}}
{{- $modelName := $modelNameSingular | titleCase -}}
{{- $modelNameCamel := $modelNameSingular | camelCase -}}

{{ import "bunnymarshal" "github.com/sqlbunny/bunnymarshal" }}

{{range $marshaler := .Marshalers }}
{{- $marshalerName := $marshaler.Name | titleCase -}}

type {{$modelName}}Marshaled{{$marshalerName}} struct {
	{{range $field := $marshaler.Fields }}
	{{titleCase $field.Name}} {{goType $field.GoType}} `{{$field.GenerateTags}}`
	{{- end }}
	{{range $field := $marshaler.CustomFields }}
	{{titleCase $field.Name}} {{goType $field.GoType}} `{{$field.GenerateTags}}`
	{{- end }}
	{{range $e := $marshaler.Expandables }}
	{{ $r := FindRelationship $dot.Model $e.Name -}}

	{{- if $r.ToMany -}}
	{{ $r.Name | titleCase }} []*{{ $r.ForeignModel | titleCase }}Marshaled{{$marshalerName}} `json:"{{$r.Name}},omitempty"`
	{{ else -}}
	{{ $r.Name | titleCase }} *{{ $r.ForeignModel | titleCase }}Marshaled{{$marshalerName}} `json:"{{$r.Name}},omitempty"`
	{{ end -}}

	{{- end }}
}

func (o *{{$modelName}}) doMarshal{{$marshalerName}}(ctx context.Context, opts *bunnymarshal.Options) (*{{$modelName}}Marshaled{{$marshalerName}}, error) {
    if o == nil {
        return nil, nil
    }

	res := &{{$modelName}}Marshaled{{$marshalerName}}{
        {{range $field := $marshaler.Fields }}
        {{titleCase $field.Name}}: o.{{titleCase $field.Name}},
        {{- end }}
        {{range $field := $marshaler.CustomFields }}
        {{titleCase $field.Name}}: {{$field.Expr}},
        {{- end }}
	}
	if opts != nil && o.R != nil {
		for _, e := range opts.Expand {
			var err error
			switch e {
				{{range $e := $marshaler.Expandables }}
				{{ $r := FindRelationship $dot.Model $e.Name -}}
				case "{{$r.Name}}":
					res.{{ $r.Name | titleCase }}, err = o.R.{{ $r.Name | titleCase }}.Marshal{{$marshalerName}}(ctx, nil)
				{{- end }}
				default:
					err = &bunnymarshal.UnknownExpandableError{
						Model: "{{$dot.Model.Name}}",
						Expandable: e,
					}
			}
			if err != nil {
				return nil, err
			}
		}
	}
	return res, nil
}

func (o *{{$modelName}}) Marshal{{$marshalerName}}(ctx context.Context, opts *bunnymarshal.Options) (*{{$modelName}}Marshaled{{$marshalerName}}, error) {
    if o == nil {
        return nil, nil
    }

	var err error

	{{range $load := $marshaler.Loads }}
	err = {{$modelNameCamel}}L{}.Load{{$load.Name | titleCase}}(ctx, []*{{$modelName}}{o})
	if err != nil {
		return nil, err
	}
	{{- end }}

	if opts != nil {
		for _, e := range opts.Expand {
			switch e {
				{{range $e := $marshaler.Expandables }}
				{{ $r := FindRelationship $dot.Model $e.Name -}}
				case "{{$r.Name}}":
					err = {{$modelNameCamel}}L{}.Load{{ $r.Name | titleCase }}(ctx, []*{{$modelName}}{o})
				{{- end }}
				default:
					err = &bunnymarshal.UnknownExpandableError{
						Model: "{{$dot.Model.Name}}",
						Expandable: e,
					}
			}
			if err != nil {
				return nil, err
			}
		}
	}

	return o.doMarshal{{$marshalerName}}(ctx, opts)
}


func (s {{$modelName}}Slice) Marshal{{$marshalerName}}(ctx context.Context, opts *bunnymarshal.Options) ([]*{{$modelName}}Marshaled{{$marshalerName}}, error) {
	if s == nil {
        return nil, nil
	}

	var err error

	{{range $load := $marshaler.Loads }}
	err = {{$modelNameCamel}}L{}.Load{{$load.Name | titleCase}}(ctx, s)
	if err != nil {
		return nil, err
	}
	{{- end }}
	if opts != nil {
		for _, e := range opts.Expand {
			switch e {
				{{range $e := $marshaler.Expandables }}
				{{ $r := FindRelationship $dot.Model $e.Name -}}
				case "{{$r.Name}}":
					err = {{$modelNameCamel}}L{}.Load{{ $r.Name | titleCase }}(ctx, s)
				{{- end }}
				default:
					err = &bunnymarshal.UnknownExpandableError{
						Model: "{{$dot.Model.Name}}",
						Expandable: e,
					}
			}
			if err != nil {
				return nil, err
			}
		}
	}

	res := make([]*{{$modelName}}Marshaled{{$marshalerName}}, len(s))
	for i, o := range s {
		res[i], err = o.doMarshal{{$marshalerName}}(ctx, opts)
		if err !=  nil {
			return nil, err
		}
	}
	return res, nil
}

{{end}}

func (o *{{$modelName}}) Marshal(ctx context.Context, marshaler string, opts *bunnymarshal.Options) (any, error) {
{{if .Marshalers}}
	switch marshaler {
{{range $marshaler := .Marshalers -}}
{{- $marshalerName := $marshaler.Name | titleCase -}}
		case "{{$marshaler.Name}}": return o.Marshal{{$marshalerName}}(ctx, opts)
{{ end }}
		default:
			return nil, &bunnymarshal.UnknownMarshalerError{
				Model: "{{$dot.Model.Name}}",
				Marshaler: marshaler,
			}
	}
{{ else }}
	return nil, &bunnymarshal.UnknownMarshalerError{
		Model: "{{$dot.Model.Name}}",
		Marshaler: marshaler,
	}
{{ end }}
}

func (s {{$modelName}}Slice) Marshal(ctx context.Context, marshaler string, opts *bunnymarshal.Options) (any, error) {
{{if .Marshalers}}
	switch(marshaler) {
{{range $marshaler := .Marshalers -}}
{{- $marshalerName := $marshaler.Name | titleCase -}}
		case "{{$marshaler.Name}}": return s.Marshal{{$marshalerName}}(ctx, opts)
{{ end }}
		default:
			return nil, &bunnymarshal.UnknownMarshalerError{
				Model: "{{$dot.Model.Name}}",
				Marshaler: marshaler,
			}
	}
{{ else }}
	return nil, &bunnymarshal.UnknownMarshalerError{
		Model: "{{$dot.Model.Name}}",
		Marshaler: marshaler,
	}
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

func (o *{{$modelName}}) ReverseMarshal(ctx context.Context, m any) error {
{{if .Marshalers}}
	switch m := m.(type) {
{{range $marshaler := .Marshalers -}}
{{- $marshalerName := $marshaler.Name | titleCase -}}
		case *{{$modelName}}Marshaled{{$marshalerName}}: o.ReverseMarshal{{$marshalerName}}(ctx, m)
{{ end }}
		default:
			return &bunnymarshal.UnknownMarshalerError{
				Model: "{{$dot.Model.Name}}",
				Marshaler: fmt.Sprintf("%T", m),
			}
	}
	return nil
{{ else }}
	return &bunnymarshal.UnknownMarshalerError{
		Model: "{{$dot.Model.Name}}",
		Marshaler: fmt.Sprintf("%T", m),
	}
{{ end }}
}


{{ if .PoisonMarshalJSON }}
func (o *{{$modelName}}) MarshalJSON() ([]byte, error) {
    panic("Model instances must not be JSON marshaled directly. Go through a marshaler instead")
}
func (o *{{$modelName}}) UnmarshalJSON(data []byte) error {
    panic("Model instances must not be JSON marshaled directly. Go through a marshaler instead")
}
{{ end }}

func (o *{{$modelName}}) PrimaryKeyColumns() ([]string) {
	return {{$modelNameCamel}}PrimaryKeyColumns
}

func (o {{$modelName}}Slice) PrimaryKeyColumns() ([]string) {
	return {{$modelNameCamel}}PrimaryKeyColumns
}
