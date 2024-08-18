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
            -- last     = (doesn't need to be specified)
            interaction = "all",
        },
        {
            filename    = "toclinks",
            first       = 999, --cover3, page1 (last page of toclinks.pdf)
            -- last     = first+1, --cover3, when it needs two pages
            interaction = "all",
            pageoffset  = 0,
        },
    },
}

