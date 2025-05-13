package gen

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
	// TODO fix this horrible hack. The plugin API should have a way to define custom functions for plugin templates.
	gen.TemplateFunctions["FindRelationship"] = func(t *schema.Model, name string) *schema.Relationship {
		for _, r := range t.Relationships {
			if r.Name == name {
				return r
			}
		}
		return nil
	}

	p.modelTemplate = gen.MustLoadTemplate(templatesPackage, "templates/model.tpl")
	gen.OnHook("model", p.modelHook)
}

func (p *Plugin) modelHook(buf *bytes.Buffer, data map[string]any, args ...any) {
	m := data["Model"].(*schema.Model)
	data["Marshalers"] = ModelGetMarshalers(m)
	data["PoisonMarshalJSON"] = p.PoisonMarshalJSON

	p.modelTemplate.ExecuteBuf(data, buf)
}
