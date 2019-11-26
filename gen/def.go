package gen

import (
	"fmt"

	"github.com/sqlbunny/sqlbunny/gen/core"
	"github.com/sqlbunny/sqlbunny/schema"
)

type MarshalerContext struct {
	*core.ModelContext
	Marshaler *ModelMarshaler
}

type MarshalerItem interface {
	MarshalerItem(ctx *MarshalerContext)
}

type defMarshaler struct {
	name  string
	items []MarshalerItem
}

func (d defMarshaler) ModelItem(ctx *core.ModelContext) {
	ctx.Enqueue(300, func() {
		s := &ModelMarshaler{
			Name: d.name,
		}

		for _, i := range d.items {
			i.MarshalerItem(&MarshalerContext{
				ModelContext: ctx,
				Marshaler:    s,
			})
		}

		ModelAddMarshaler(ctx.Model, s)
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

func (d defField) MarshalerItem(ctx *MarshalerContext) {
	f := ctx.Model.FindField(d.name)
	if f == nil {
		ctx.AddError("Model %s marshaler %s: field %s does not exist", ctx.Model.Name, ctx.Marshaler.Name, d.name)
		return
	}
	ctx.Marshaler.Fields = append(ctx.Marshaler.Fields, f)
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

func (d defCustomField) MarshalerItem(ctx *MarshalerContext) {
	t := ctx.GetType(d.typeName, fmt.Sprintf("Marshaler '%s' field '%s'", ctx.Marshaler.Name, d.name))
	if t == nil {
		return
	}

	ctx.Marshaler.CustomFields = append(ctx.Marshaler.CustomFields, &MarshalerCustomField{
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

func (d defLoad) MarshalerItem(ctx *MarshalerContext) {
	ctx.Marshaler.Loads = append(ctx.Marshaler.Loads, &MarshalerLoad{
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

func (d defExpandable) MarshalerItem(ctx *MarshalerContext) {
	ctx.Marshaler.Expandables = append(ctx.Marshaler.Expandables, &MarshalerExpandable{
		Name: d.name,
	})
}

func Expandable(name string) defExpandable {
	return defExpandable{
		name: name,
	}
}

type defInherit struct {
	name string
}

func (d defInherit) MarshalerItem(ctx *MarshalerContext) {
	ctx.Enqueue(400, func() {
		m1 := ctx.Marshaler
		m2 := ModelFindMarshaler(ctx.Model, d.name)
		if m2 == nil {
			ctx.AddError("Marshaler %s does not exist", d.name)
			return
		}

		m1.Fields = append(m1.Fields, m2.Fields...)
		m1.CustomFields = append(m1.CustomFields, m2.CustomFields...)
		m1.Loads = append(m1.Loads, m2.Loads...)
		m1.Expandables = append(m1.Expandables, m2.Expandables...)
	})
}

func Inherit(name string) defInherit {
	return defInherit{
		name: name,
	}
}
