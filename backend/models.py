from database.base import (
    Base,
    User,
    Protocol,
    Knowledge,
    Question,
    Solution,
    Feedback,
    solution_references_knowledge as solution_knowledge_link,
)
import datetime

# This file doesn't need to define the classes again,
# as they are imported from base.py.
# The purpose of this file might be to make these models
# easily accessible from a single module, e.g., from backend import models 