-- $Id$
-- Public domain.
-- Lua template file for use with ConTeXt to preserve all the links,
-- both internal and external, in the file tbNNNcomplete.pdf. See
-- the Makefile for the invocation and tb138prod.pdf for a published note.
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
            pageoffset  = 0,
        },
        {
            filename    = "toclinks",
            first = 119,
            -- not working yet: first       = -1, --cover3, last page of toclinks.pdf
            --   last        = -1, --just that page
            -- 
            -- sometimes cover3 spills over backwards onto the last
            -- regular page. Then we use:
            --first       = -2, --cover3, second to last page of toclinks.pdf
            --last        = -1, --last page of toclinks.pdf
            interaction = "all",
            pageoffset  = 0,
        },
    },
}

