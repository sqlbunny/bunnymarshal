package bunnymarshal

import (
	"bytes"

	"github.com/sqlbunny/sqlbunny/gen"
	"github.com/sqlbunny/sqlbunny/schema"
)

const templatesPackage = "github.com/sqlbunny/bunnymarshal/gen"

type Plugin struct {
	modelTemplate *gen.TemplateList

	PoisonMarshalJSON bool
}

var _ gen.Plugin = &Plugin{}

func (*Plugin) ConfigItem(ctx *gen.Context) {}

func (p *Plugin) BunnyPlugin() {
	p.modelTemplate = gen.MustLoadTemplate(templatesPackage, "templates/model.tpl")
	gen.OnHook("model", p.modelHook)
}

func (p *Plugin) modelHook(buf *bytes.Buffer, data map[string]interface{}, args ...interface{}) {
	m := data["Model"].(*schema.Model)
	data["Marshalers"] = ModelGetMarshalers(m)
	data["PoisonMarshalJSON"] = p.PoisonMarshalJSON
	p.modelTemplate.ExecuteBuf(data, buf)
}