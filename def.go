package bunnymarshal

import "github.com/sqlbunny/sqlbunny/gen/core"

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
