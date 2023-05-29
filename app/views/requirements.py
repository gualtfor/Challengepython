import imp
from operator import concat
from fastapi import APIRouter, Depends
from sqlalchemy.orm import session
from fastapi.responses import StreamingResponse
import pandas as pd
import io
from app.config.context import get_db, engine
from app.views.queries import sql

router = APIRouter()

@router.get("/requirements/{query}", tags=["Queries"])
async def consulta(query, db: session = Depends(get_db)):
    df = pd.read_sql_query(sql[query], engine)
    stream = io.StringIO()
    df.to_csv(stream, index=False)
    response = StreamingResponse(iter([stream.getvalue()]), media_type="text/csv")
    response.headers["Content-Disposition"] = "attachment; filename=output.csv"

    return response