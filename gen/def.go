package gen

import (
	"fmt"

	"github.com/sqlbunny/sqlbunny/gen/core"
	"github.com/sqlbunny/sqlbunny/schema"
)

type MarshalerContext interface {
	GetMarshaler() *ModelMarshaler
	GetType(name string, where string) schema.Type
	AddError(message string, args ...interface{})
}

type modelMarshalerContext struct {
	*core.ModelContext
	Marshaler *ModelMarshaler
}

func (ctx *modelMarshalerContext) GetMarshaler() *ModelMarshaler {
	return ctx.Marshaler
}

type structMarshalerContext struct {
	*core.StructContext
	Marshaler *ModelMarshaler
}

func (ctx *structMarshalerContext) GetMarshaler() *ModelMarshaler {
	return ctx.Marshaler
}

type MarshalerItem interface {
	MarshalerItem(ctx MarshalerContext)
}

type defMarshaler struct {
	name  string
	items []MarshalerItem
}

func (d defMarshaler) ModelItem(ctx *core.ModelContext) {
	if ctx.Prefix != "" {
		return
	}

	ctx.Enqueue(300, func() {
		s := &ModelMarshaler{
			Name: d.name,
		}

		for _, i := range d.items {
			i.MarshalerItem(&modelMarshalerContext{
				ModelContext: ctx,
				Marshaler:    s,
			})
		}

		ModelAddMarshaler(ctx.Model, s)
	})
}

func (d defMarshaler) StructItem(ctx *core.StructContext) {
	ctx.Enqueue(300, func() {
		s := &ModelMarshaler{
			Name: d.name,
		}

		for _, i := range d.items {
			i.MarshalerItem(&structMarshalerContext{
				StructContext: ctx,
				Marshaler:     s,
			})
		}

		StructAddMarshaler(ctx.Struct, s)
	})
}

func Marshaler(name string, items ...MarshalerItem) defMarshaler {
	return defMarshaler{
		name:  name,
		items: items,
	}
}

type defField struct {
	name string
}

func findStructField(s *schema.Struct, name string) (col *schema.Field) {
	for _, c := range s.Fields {
		if c.Name == name {
			return c
		}
	}
	return nil
}

func (d defField) MarshalerItem(ctx MarshalerContext) {
	m := ctx.GetMarshaler()
	var f *schema.Field

	switch ctx := ctx.(type) {
	case *modelMarshalerContext:
		f = ctx.Model.FindField(d.name)
		if f == nil {
			ctx.AddError("Model %s marshaler %s: field %s does not exist", ctx.Model.Name, ctx.Marshaler.Name, d.name)
			return
		}

	case *structMarshalerContext:
		f = findStructField(ctx.Struct, d.name)
		if f == nil {
			ctx.AddError("Struct %s marshaler %s: field %s does not exist", ctx.Struct.Name, ctx.Marshaler.Name, d.name)
			return
		}
	default:
		panic("unknown context")
	}
	m.Fields = append(m.Fields, f)
}

func Field(name string) defField {
	return defField{
		name: name,
	}
}

type defCustomField struct {
	name     string
	typeName string
	expr     string
}

func (d defCustomField) MarshalerItem(ctx MarshalerContext) {
	m := ctx.GetMarshaler()

	t := ctx.GetType(d.typeName, fmt.Sprintf("Marshaler '%s' field '%s'", m.Name, d.name))
	if t == nil {
		return
	}

	m.CustomFields = append(m.CustomFields, &MarshalerCustomField{
		Name:     d.name,
		Type:     t,
		Nullable: false,
		Tags:     schema.Tags{},
		Expr:     d.expr,
	})
}

func CustomField(name string, typeName string, expr string) defCustomField {
	return defCustomField{
		name:     name,
		typeName: typeName,
		expr:     expr,
	}
}

type defLoad struct {
	name string
}

func (d defLoad) MarshalerItem(ctx MarshalerContext) {
	m := ctx.GetMarshaler()
	m.Loads = append(m.Loads, &MarshalerLoad{
		Name: d.name,
	})
}

func Load(name string) defLoad {
	return defLoad{
		name: name,
	}
}

type defExpandable struct {
	name string
}

func (d defExpandable) MarshalerItem(ctx MarshalerContext) {
	m := ctx.GetMarshaler()
	m.Expandables = append(m.Expandables, &MarshalerExpandable{
		Name: d.name,
	})
}

func Expandable(name string) defExpandable {
	return defExpandable{
		name: name,
	}
}
