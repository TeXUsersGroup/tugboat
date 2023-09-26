-- $Id$
-- Public domain.
-- Lua template file for use with ConTeXt to preserve all the links,
-- both internal and external, in the file tbNNNcomplete.pdf.
-- See tb138prod.pdf for a published note about this.
return {
    list = {
        {
            filename    = "toclinks",
            first       = 1, --cover1
            last        = 2, --cover2
            interaction = "all",
            pageoffset  = 0,
        },
        {
            filename    = "../CADMUS/issue",
            first       = 1,
            last        = 176,
            interaction = "all",
        },
        {
            filename    = "toclinks",
            first       = 179, --cover3, page1
            last        = 180, --cover3, page2
            interaction = "all",
            pageoffset  = 0,
        },
    },
}

